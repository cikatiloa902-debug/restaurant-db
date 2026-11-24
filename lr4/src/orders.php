<?php
declare(strict_types=1);

function createOrder(array $order, ?int $foodId, ?int $drinkId, array $entities): int
{
    $connection = db();
    $connection->beginTransaction();
    try {
        query($entities['orders']['insert'], $order);
        $orderId = (int) $connection->lastInsertId();

        foreach (['food_id' => $foodId, 'drink_id' => $drinkId] as $column => $productId) {
            if ($productId === null) {
                continue;
            }
            $position = ['food_id' => null, 'drink_id' => null, 'reservation_id' => null, 'chef_id' => null];
            $position[$column] = $productId;
            query($entities['order-items']['insert'], ['order_id' => $orderId] + $position);
        }

        $connection->commit();
        return $orderId;
    } catch (Throwable $exception) {
        if ($connection->inTransaction()) {
            $connection->rollBack();
        }
        throw $exception;
    }
}
