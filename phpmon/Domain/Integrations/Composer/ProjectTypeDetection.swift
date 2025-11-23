//
//  Frameworks.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/01/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

struct ProjectTypeDetection {
    /**
     This list is only checked if the specific dependency list doesn't report a match.
     */
    public static let CommonDependencyList = [
        "laravel/framework": "Laravel",
        "symfony/symfony": "Symfony",
        "laravel/lumen": "Lumen",
        "tempest/framework": "Tempest"
    ]

    /**
     This list is checked first to see if a project dependency can be mapped to a certain project type.
     */
    public static let SpecificDependencyList = [
        "roots/bedrock-autoloader": "Bedrock",
        "cakephp/app": "CakePHP",
        "craftcms/craft": "Craft",
        "drupal/core": "Drupal",
        "flarum/core": "Flarum",
        "tightenco/jigsaw": "Jigsaw",
        "joomla/uri": "Joomla",
        "themsaid/katana": "Katana",
        "getkirby/cms": "Kirby",
        "october/october": "OctoberCMS",
        "sculpin/sculpin": "Sculpin",
        "statamic/cms": "Statamic",
        "johnpbloch/wordpress-core": "WordPress",
        "zendframework/zendframework": "Zend",
        "zendframework/zend-mvc": "Zend",
        "typo3/cms-core": "Typo3",
        "slim/slim": "Slim"
    ]

    /**
     There are two cases where users are unlikely to use `composer`,
     when setting up a Drupal or a WordPress project. For performance
     reasons, we only check that here!
     */
    public static func detectFallbackDependency(_ basePath: String) -> String? {
        for entry in Self.FileMapping {
            let found = entry.value
                .map { path in return App.shared.container.filesystem.anyExists(basePath + path) }
                .contains(true)

            if found {
                return entry.key
            }
        }

        return nil
    }

    /**
     File mapping is used as a fallback if neither specific nor framework matches could be done.
     */
    public static let FileMapping: [String: [String]] = [
        "Drupal": [
            // Legacy installations
            "/misc/drupal.js",
            "/core/lib/Drupal.php",
            // The default (new) installation w/ Composer puts the modules in /web
            "/web/misc/drupal.js",
            "/web/core/lib/Drupal.php"
        ],
        "WordPress": [
            "/wp-config.php",
            "/wp-config-sample.php"
        ],
        "Typo3": [
            "/typo3",
            "/public/typo3"
        ]
    ]
}
