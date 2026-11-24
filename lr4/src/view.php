<!doctype html>
<html lang="uk">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h($title) ?> | Ресторан</title>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
<header class="site-header">
    <div class="brand"><a href="/">Ресторан</a><span>Облік ресторану</span></div>
    <nav aria-label="Розділи">
        <?php foreach ($entities as $key => $item): ?>
            <a href="<?= h(url($key)) ?>" <?= $section === $key ? 'aria-current="page"' : '' ?>><?= h($item['title']) ?></a>
        <?php endforeach; ?>
    </nav>
</header>
<main>
    <?php if ($mode === 'list'): ?>
        <div class="page-heading">
            <div>
                <h1><?= h($title) ?></h1>
                <p><?= h($entity['description']) ?></p>
            </div>
            <a class="button primary" href="<?= h(url($section, ['action' => 'create'])) ?>">Додати запис</a>
        </div>
    <?php else: ?>
        <a class="back" href="<?= h($entity ? url($section) : '/') ?>">← <?= h($entity['title'] ?? 'До замовлень') ?></a>
        <h1><?= h($title) ?></h1>
    <?php endif; ?>

    <?php if ($notice && $mode === 'list'): ?>
        <p class="notice <?= $notice['kind'] === 'error' ? 'error' : 'success' ?>" role="status"><?= h($notice['text']) ?></p>
    <?php endif; ?>

    <?php if ($mode === 'error'): ?>
        <p class="notice error" role="alert"><?= h($message) ?></p>
    <?php elseif ($mode === 'list'): ?>
        <section class="panel" aria-label="Записи">
            <div class="table-toolbar">
                <strong>Записів: <?= h($total) ?></strong>
                <?php if (isset($entity['count'])): ?>
                    <form class="search" method="get">
                        <input type="hidden" name="section" value="<?= h($section) ?>">
                        <input type="search" aria-label="Пошук замовлень" name="q" maxlength="100" value="<?= h($search) ?>" placeholder="Номер, клієнт або статус">
                        <button class="button" type="submit">Знайти</button>
                        <?php if ($search !== ''): ?>
                            <a class="button" href="<?= h(url($section)) ?>">Очистити</a>
                        <?php endif; ?>
                    </form>
                <?php endif; ?>
            </div>
            <div class="table-scroll">
                <table>
                    <thead><tr>
                        <th scope="col">№</th>
                        <?php foreach ($entity['columns'] as $label): ?>
                            <th scope="col"><?= h($label) ?></th>
                        <?php endforeach; ?>
                        <th scope="col">Дії</th>
                    </tr></thead>
                    <tbody>
                    <?php if (!$rows): ?>
                        <tr><td class="empty" colspan="<?= h(count($entity['columns']) + 2) ?>">Записів не знайдено.</td></tr>
                    <?php endif; ?>
                    <?php foreach ($rows as $row): ?>
                        <?php $rowId = $row[$entity['pk']]; ?>
                        <tr>
                            <th scope="row"><?= h($rowId) ?></th>
                            <?php foreach ($entity['columns'] as $key => $label): ?>
                                <td><?= h($row[$key] ?? '—') ?></td>
                            <?php endforeach; ?>
                            <td class="actions">
                                <a href="<?= h(url($section, ['action' => 'edit', 'id' => $rowId])) ?>">Редагувати</a>
                                <a class="danger-link" href="<?= h(url($section, ['action' => 'confirm', 'id' => $rowId])) ?>">Видалити</a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php if (isset($pages) && $pages > 1): ?>
                <nav class="pagination" aria-label="Сторінки замовлень">
                    <?php if ($page > 1): ?>
                        <a class="button" href="<?= h(url($section, ['q' => $search, 'page' => $page - 1])) ?>">← Попередня</a>
                    <?php endif; ?>
                    <span>Сторінка <?= h($page) ?> з <?= h($pages) ?></span>
                    <?php if ($page < $pages): ?>
                        <a class="button" href="<?= h(url($section, ['q' => $search, 'page' => $page + 1])) ?>">Наступна →</a>
                    <?php endif; ?>
                </nav>
            <?php endif; ?>
        </section>
    <?php elseif ($mode === 'confirm'): ?>
        <form class="panel card" method="post" action="<?= h(url($section, ['action' => 'delete', 'id' => $id])) ?>">
            <input type="hidden" name="csrf" value="<?= h(csrfToken()) ?>">
            <p>Видалити запис №<?= h($id) ?> з розділу «<?= h($entity['title']) ?>»?</p>
            <div class="form-actions">
                <button class="button danger" type="submit">Видалити запис</button>
                <a class="button" href="<?= h(url($section)) ?>">Скасувати</a>
            </div>
        </form>
    <?php elseif ($mode === 'form'): ?>
        <form class="panel card" method="post" novalidate>
            <input type="hidden" name="csrf" value="<?= h(csrfToken()) ?>">
            <?php if (isset($errors['_form'])): ?>
                <p class="notice error" role="alert"><?= h($errors['_form']) ?></p>
            <?php endif; ?>
            <?php if ($compound): ?>
                <p class="hint">Можна додати страву та напій. Кожен вибраний пункт збережеться окремою позицією цього замовлення.</p>
            <?php elseif (!empty($entity['product'])): ?>
                <p class="hint">Виберіть одну страву або один напій.</p>
            <?php endif; ?>
            <?php foreach ($fields as $name => [$label, $type, $required]): ?>
                <?php $value = $type === 'password' ? '' : (string) ($values[$name] ?? ''); ?>
                <div class="field">
                    <label for="<?= h($name) ?>"><?= h($label) ?><?= $required ? ' *' : '' ?></label>
                    <?php if ($type === 'select'): ?>
                        <select id="<?= h($name) ?>" name="<?= h($name) ?>" <?= isset($errors[$name]) ? 'aria-invalid="true" aria-describedby="' . h($name) . '-error"' : '' ?>>
                            <option value=""><?= $required ? 'Виберіть запис' : '—' ?></option>
                            <?php foreach ($choices[$name] as $optionId => $optionLabel): ?>
                                <option value="<?= h($optionId) ?>" <?= $value === (string) $optionId ? 'selected' : '' ?>><?= h($optionLabel) ?></option>
                            <?php endforeach; ?>
                        </select>
                    <?php else: ?>
                        <?php $inputType = in_array($type, ['email', 'date', 'password'], true) ? $type : 'text'; ?>
                        <input id="<?= h($name) ?>" name="<?= h($name) ?>" type="<?= h($inputType) ?>" value="<?= h($value) ?>"
                            <?= $type === 'money' ? 'inputmode="decimal"' : '' ?>
                            <?= $type === 'integer' ? 'inputmode="numeric"' : '' ?>
                            <?= $type === 'password' ? 'autocomplete="new-password"' : '' ?>
                            <?= isset($errors[$name]) ? 'aria-invalid="true" aria-describedby="' . h($name) . '-error"' : '' ?>>
                    <?php endif; ?>
                    <?php if (isset($errors[$name])): ?>
                        <span class="field-error" id="<?= h($name) ?>-error" role="alert"><?= h($errors[$name]) ?></span>
                    <?php elseif ($type === 'password' && !$required): ?>
                        <span class="hint">Залиште порожнім, щоб зберегти чинний пароль.</span>
                    <?php elseif ($name === 'order_status'): ?>
                        <span class="hint">Наприклад, new, preparing, completed або cancelled.</span>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
            <div class="form-actions">
                <button class="button primary" type="submit">Зберегти</button>
                <a class="button" href="<?= h(url($section)) ?>">Скасувати</a>
            </div>
        </form>
    <?php endif; ?>
</main>
</body>
</html>
