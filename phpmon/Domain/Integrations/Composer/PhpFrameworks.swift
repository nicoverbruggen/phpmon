//
//  Frameworks.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct PhpFrameworks {
    
    /// This list should probably be reversed when checked, because some of these
    /// will also require either laravel/framework or symfony/symfony.
    public static let DependencyList = [

        // COMMON FRAMEWORKS
        "laravel/framework" : "Laravel",
        "symfony/symfony": "Symfony",
        "laravel/lumen": "Lumen",
        
        // VARIOUS CMS
        "roots/bedrock": "Bedrock",
        "cakephp/app": "CakePHP",
        
        // TODO: Handle wildcards like these (currently disabled)
        // "concrete5/*": "Concrete5",
        // "contao/*": "Contao",
        
        "craftcms/craft": "Craft",
        "drupal/core": "Drupal",
        "flarum/core": "Flarum",
        "tightenco/jigsaw": "Jigsaw",
        "joomla/uri": "Joomla",
        "themsaid/katana": "Katana",
        "getkirby/cms": "Kirby",
        // "magento/*": "Magento",
        "october/october": "OctoberCMS",
        "sculpin/sculpin": "Sculpin",
        // "slim/*": "Slim",
        "statamic/cms": "Statamic",
        "johnpbloch/wordpress-core": "Wordpress",
        "zendframework/zendframework": "Zend",
        "zendframework/zend-mvc": "Zend"
    ]
    
}
