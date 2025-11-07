//
//  ValetTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

class ValetVersionExtractorTest {
    @Test func test_can_determine_valet_version_regardless_of_deprecations() async {
        let output = """
        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::offsetExists($key) should either be compatible with ArrayAccess::offsetExists(mixed $offset): bool, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1789

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::offsetGet($key) should either be compatible with ArrayAccess::offsetGet(mixed $offset): mixed, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1800

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::offsetSet($key, $value) should either be compatible with ArrayAccess::offsetSet(mixed $offset, mixed $value): void, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1812

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::offsetUnset($key) should either be compatible with ArrayAccess::offsetUnset(mixed $offset): void, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1827

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::count() should either be compatible with Countable::count(): int, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1768

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::getIterator() should either be compatible with IteratorAggregate::getIterator(): Traversable, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1747

        Deprecated: Return type of Tightenco\\Collect\\Support\\Collection::jsonSerialize() should either be compatible with JsonSerializable::jsonSerialize(): mixed, or the #[\\ReturnTypeWillChange] attribute should be used to temporarily suppress the notice in /Users/dummy/.composer/vendor/tightenco/collect/src/Collect/Support/Collection.php on line 1716
        Laravel Valet 3.3.0
        """

        let versionString = output
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "Laravel Valet")[1]
            .trimmingCharacters(in: .whitespaces)

        let version = try! VersionNumber.parse(VersionExtractor.from(versionString)!)

        #expect(version.major == 3)
    }
}
