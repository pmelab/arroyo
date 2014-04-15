<?php
// Gather alias definitions for all drupal projects.
foreach (glob('/var/www/*/profiles/*/drush/*.aliases.drushrc.php') as $file) {
  $options['alias-path'][] = dirname($file);
}
array_unique($options['alias-path']);
$options['dump-dir'] = '/tmp';
