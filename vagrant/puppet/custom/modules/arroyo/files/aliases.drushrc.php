<?php
// Standard aliases for everything thats a drupal directory.
foreach (glob('/var/www/*/profiles') as $file) {
  $platform = preg_replace('/^\/var\/www\/([a-z]+)\/profiles$/', '$1', $file);
  $aliases[$platform] = array(
    'uri' => 'http://arroyo.local/drupal/' . $platform,
    'root' => '/var/www/' . $platform,
    'db-url' => 'mysql://root:root@localhost:3306/' . $platform,
  );
}
