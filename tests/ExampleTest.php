<?php

declare(strict_types=1);

namespace WickedByte\Tests\LibrarySkeleton;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;
use WickedByte\LibrarySkeleton\Example;

final class ExampleTest extends TestCase
{
    #[Test]
    public function barReturnsTheAnswerToLifeTheUniverseAndEverything(): void
    {
        self::assertSame(42, Example::bar());
    }
}
