const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const path = require('node:path');

const baseURL = 'http://127.0.0.1:8080';
const output = path.resolve('screens');
const sql = (command) => execFileSync('docker', [
    'compose', 'exec', '-T', 'db', 'sh', '-c',
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql --protocol=TCP -h127.0.0.1 -uroot --default-character-set=utf8mb4 -N restaurant_db -e "$1"',
    'mysql', command
], {cwd:'lr4', encoding:'utf8'}).trim();

const endpoint = (section, action, id) => {
    const query = new URLSearchParams({section});
    if (action) query.set('action', action);
    if (id) query.set('id', id);
    return '/?' + query;
};

(async () => {
    const browser = await chromium.launch({ headless: true,
        args: ['--no-sandbox', '--disable-dev-shm-usage', '--no-proxy-server'] });
    try {
        const context = await browser.newContext({baseURL, viewport:{width:1150,height:875}, deviceScaleFactor:1});
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', error => errors.push(String(error)));
        async function open(url, expected = 200) {
            const response = await page.goto(url);
            assert.equal(response.status(), expected, url);
            assert.equal(await page.locator('h1').count(), 1);
        }
        async function snap(name) {
            await page.screenshot({path: path.join(output, name + '.png')});
        }
        async function save(expected = 200) {
            const [result] = await Promise.all([
                page.waitForNavigation(), page.getByRole('button', {name:'Зберегти'}).click()
            ]);
            assert.equal(result.status(), expected);
        }
        async function apiPost(section, action, form, id, expected = 303) {
            await open(endpoint(section, action === 'delete' ? 'confirm' : action, id));
            const csrf = await page.locator('input[name=csrf]').inputValue();
            const response = await context.request.post(endpoint(section, action, id), {form:{csrf,...form}, maxRedirects:0});
            assert.equal(response.status(), expected, section + ' ' + action);
            return response;
        }
        async function deleteRecord(section, id) {
            await apiPost(section, 'delete', {}, id);
            await open(endpoint(section));
            assert.match(await page.locator('.notice').innerText(), /Запис видалено/);
        }

        await open('/');
        assert.match(await page.locator('.table-toolbar').innerText(), /Записів: 15/);
        assert.equal(await page.locator('tbody tr').count(), 8);
        await snap('01-orders');
        await page.getByRole('link', {name:'Наступна'}).click();
        assert.equal(await page.locator('tbody tr').count(), 7);
        await page.getByRole('searchbox').fill('Коваль');
        await page.getByRole('button', {name:'Знайти'}).click();
        assert.equal(await page.locator('tbody tr').count(), 3);
        await page.getByRole('searchbox').fill("Коваль'");
        await page.getByRole('button', {name:'Знайти'}).click();
        assert.match(await page.locator('tbody').innerText(), /Записів не знайдено/);
        await snap('05-search');

        await open(endpoint('food','create'));
        await snap('02-create');
        await save(422);
        assert.equal(await page.locator('.field-error').count(), 2);
        await snap('03-validation');
        await page.locator('#name').fill('Десерт <сезонний>');
        await page.locator('#description').fill('З ягідним соусом');
        await page.locator('#price').fill('85,50');
        await save();
        assert.match(await page.locator('.notice').innerText(), /Запис додано/);
        let row = page.getByRole('row').filter({hasText:'Десерт <сезонний>'});
        const foodId = await row.getByRole('rowheader').innerText();
        assert.equal(await row.locator('td').first().innerHTML(), 'Десерт &lt;сезонний&gt;');
        await snap('06-escape');
        await page.reload();
        assert.equal(await row.count(), 1);
        await row.getByRole('link',{name:'Редагувати'}).click();
        assert.equal(await page.locator('#price').inputValue(), '85.50');
        await page.locator('#price').fill('90');
        await save();
        assert.match(await row.innerText(), /90\.00/);
        await row.getByRole('link',{name:'Видалити'}).click();
        await snap('04-delete');
        await page.getByRole('button', {name:'Видалити запис'}).click();
        assert.equal(await row.count(), 0);
        assert.match(await page.locator('.notice').innerText(), /Запис видалено/);
        await snap('09-deleted');
        assert.equal(sql('SELECT COUNT(*) FROM food WHERE food_id=' + foodId), '0');

        const invalid = await context.request.post(endpoint('food','create'), {form:{name:'Перевірка',price:'10'}});
        assert.equal(invalid.status(), 419);
        await open(endpoint('food','delete',1), 405);
        await open(endpoint('food','edit',2147483647), 404);
        await apiPost('food','delete',{},1);
        await open(endpoint('food'));
        assert.match(await page.locator('.notice').innerText(), /використовується/);
        await apiPost('orders','create',{user_id:'2147483647',order_status:'new'},undefined,422);
        assert.equal(sql('SELECT COUNT(*) FROM food'), '12');

        const checks = [
            ['drinks','drink','drink_id',{name:'Тестовий чай',description:'М’ята',price:'14.20'}, {name:'Чай з м’ятою'}],
            ['clients','user','user_id',{first_name:'Тест',last_name:'Клієнт',email:'verify-lr4@example.test',password:'Demo-pass-42'}, {last_name:'Клієнт 2',password:''}],
            ['chefs','chef','chef_id',{name:'Кухар тест',specialization:'Десерти'}, {specialization:'Випічка'}],
            ['reservations','reservation','reservation_id',{user_id:'3',reserved_date:'2026-11-24',table_number:'19'}, {table_number:'20'}],
            ['specialties','chef_specialty','chef_specialty_id',{chef_id:'1',food_id:'12',drink_id:''}, {food_id:'11'}],
            ['order-items','order_item','order_item_id',{order_id:'1',food_id:'12',drink_id:'',reservation_id:'',chef_id:''}, {food_id:'',drink_id:'6'}],
            ['notifications','notification','notification_id',{order_id:'1',message:'Дубль'}, {}, true],
            ['payments','transaction','transaction_id',{order_id:'11',amount:'98.20',transaction_date:'2026-11-24'}, {amount:'103.20'}],
        ];

        for (const [section,table,pk,form,changes,unique] of checks) {
            if (unique) {
                await apiPost(section,'create',form,undefined,422);
                continue;
            }
            await apiPost(section,'create',form);
            const id = sql('SELECT MAX(' + pk + ') FROM `' + table + '`');
            await open(endpoint(section));
            assert.equal(await page.locator('tbody th').first().innerText(), id);
            await apiPost(section,'edit',{...form,...changes},id);
            await open(endpoint(section,'edit',id));
            for (const [field,value] of Object.entries(changes)) {
                assert.equal(await page.locator('#'+field).inputValue(),value);
            }
            if (section === 'clients') {
                assert.match(sql('SELECT password FROM `user` WHERE user_id=' + id), /^\$2[ayb]\$/);
            }
            await deleteRecord(section,id);
        }

        await open(endpoint('orders','create'));
        await page.locator('#user_id').selectOption('3');
        await page.locator('#food_id').selectOption('1');
        await page.locator('#drink_id').selectOption('2');
        await save();
        assert.match(await page.locator('.notice').innerText(), /Додано позицій: 2/);
        await snap('07-commit');
        const orderId = sql('SELECT MAX(order_id) FROM `order`');
        const itemIds = sql('SELECT order_item_id FROM order_item WHERE order_id=' + orderId).split('\n');
        assert.equal(itemIds.length,2);
        await apiPost('orders','edit',{user_id:'3',order_status:'preparing'},orderId);
        assert.equal(sql('SELECT order_status FROM `order` WHERE order_id='+orderId),'preparing');

        await apiPost('notifications','create',{order_id:orderId,message:'Прийнято'});
        const notificationId = sql('SELECT notification_id FROM notification WHERE order_id='+orderId);
        await apiPost('notifications','edit',{order_id:orderId,message:'Готується'},notificationId);
        assert.equal(sql('SELECT message FROM notification WHERE notification_id='+notificationId),'Готується');
        await deleteRecord('notifications',notificationId);
        await apiPost('orders','delete',{},orderId);
        await open(endpoint('orders'));
        assert.match(await page.locator('.notice').innerText(), /використовується/);
        for (const itemId of itemIds) await deleteRecord('order-items',itemId);
        await deleteRecord('orders',orderId);

        const counts = () => sql('SELECT (SELECT COUNT(*) FROM `order`), (SELECT COUNT(*) FROM order_item)');
        const before = counts();
        sql("DROP TRIGGER IF EXISTS verify_position_failure;");
        sql("DELIMITER //\nCREATE TRIGGER verify_position_failure BEFORE INSERT ON order_item FOR EACH ROW BEGIN IF NEW.drink_id IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Контрольна помилка другої позиції'; END IF; END//\nDELIMITER ;");
        try {
            await open(endpoint('orders','create'));
            await page.locator('#user_id').selectOption('3');
            await page.locator('#food_id').selectOption('1');
            await page.locator('#drink_id').selectOption('2');
            await save(409);
            assert.match(await page.locator('.notice').innerText(), /Зміни відкотилися/);
            await snap('08-rollback');
            assert.equal(counts(),before);
            assert.equal(counts(),'15\t30');
        } finally {
            sql('DROP TRIGGER verify_position_failure');
        }
        assert.deepEqual(errors,[]);
        assert.deepEqual(await browser.newContext({viewport:{width:390,height:844}, isMobile:true, hasTouch:true}).then(async mobile => {
            try {
                const mobilePage = await mobile.newPage();
                const response = await mobilePage.goto(baseURL);
                const viewWidth = await mobilePage.evaluate(() => document.documentElement.scrollWidth);
                return [response.status(), viewWidth];
            } finally {
                await mobile.close();
            }
        }), [200,390]);
        console.log('PASS: 10 CRUD sections, 404/405/419/422, dependency errors, PRG, search, escaping, 2 pages, commit and rollback.');
    } finally {
        await browser.close();
    }
})().catch(error => {console.error(error);process.exitCode = 1;});
