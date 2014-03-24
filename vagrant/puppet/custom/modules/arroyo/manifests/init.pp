class arroyo {
/* Define dotdeb sources. */
  apt::source { 'dotdeb-base':
    location          => 'http://packages.dotdeb.org',
    release           => 'wheezy',
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    pin               => '999',
    include_src       => true,
  }

  /*
  apt::source { 'dotdeb-php54':
    location          => 'http://packages.dotdeb.org',
    release           => 'squeeze-php54',
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    pin               => '1001',
    include_src       => true,
  }
  */

  apt::source { 'dotdeb-php55':
    location          => 'http://packages.dotdeb.org',
    release           => 'wheezy-php55',
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    pin               => '1001',
    include_src       => true,
  }

  /* Basic software. */
  package { 'git-core': }
  package { 'vim': }
  package { 'ctags': }

  /* Mysql */
  class { 'mysql::server':
    root_password => 'root',
    override_options => { 'mysqld' => { 'bind_address' => '0.0.0.0' }},
    require => Apt::Source['dotdeb-base'],
  }

  /* NGINX */
  package { 'nginx':
    require => Apt::Source['dotdeb-base'],
  }

  service { 'nginx':
    ensure => 'running',
    enable => true,
    require => Package['nginx'],
  }

  file { '/etc/nginx/sites-enabled/arroyo.local':
    ensure => 'file',
    source => 'puppet:///modules/arroyo/nginx.conf',
    require => Package['nginx'],
    notify => Service['nginx']
  }

  file { '/etc/nginx/arroyo':
    ensure => 'file',
    source => 'puppet:///modules/arroyo/nginx',
    recurse => true,
    require => Package['nginx'],
    notify => Service['nginx']
  }

  /* PHP */
  package { 'php5-fpm':
    require => Apt::Source['dotdeb-php55'],
  }

  service {'php5-fpm':
    ensure => 'running',
    enable => true,
    require => Package['php5-fpm'],
  }

  package { 'php5-dev':
    require => Package['php5-fpm'],
  }

  package { 'php-pear':
    require => Package['php5-fpm'],
  }

  package { 'php5-mysql':
    require => Package['php5-fpm'],
  }

  package { 'php5-gd':
    require => Package['php5-fpm'],
  }

  package { 'php5-curl':
    require => Package['php5-fpm'],
  }

  package { 'php5-sqlite':
    require => Package['php5-fpm'],
  }

  package { 'xdebug':
    require => Package['php5-dev', 'php-pear'],
    provider => 'pecl',
  }

  package { 'apc':
    require => Package['php5-dev', 'php-pear'],
    provider => 'pecl',
  }

  package { 'xhprof':
    require => Package['php5-dev', 'php-pear'],
    provider => 'pecl',
    source => 'channel://pecl.php.net/xhprof-0.9.4',
  }

  file { '/etc/php5/fpm/conf.d/25-arroyo.ini':
    ensure => 'file',
    source => 'puppet:///modules/arroyo/php.ini',
    require => [
      Package['php5-dev'],
      Package['php-pear'],
      Package['php5-mysql'],
      Package['php5-gd'],
      Package['php5-curl'],
      Package['php5-sqlite'],
      Package['xdebug'],
      Package['apc'],
      Package['xhprof']
    ],
    notify => Service['php5-fpm'],
  }

  file { '/etc/php5/fpm/pool.d/25-arroyo.conf':
    ensure => 'file',
    source => 'puppet:///modules/arroyo/php-fpm.conf',
    require => [
      Package['php5-dev'],
      Package['php-pear'],
      Package['php5-mysql'],
      Package['php5-gd'],
      Package['php5-curl'],
      Package['php5-sqlite'],
      Package['xdebug'],
      Package['apc'],
      Package['xhprof']
    ],
    notify => Service['php5-fpm'],
  }

  /* Networking */
  package {'avahi-daemon': }
  service {'avahi-daemon':
    ensure => 'running',
    enable => true,
    require => Package['avahi-daemon']
  }

  package {'dnsmasq': }
    service {'dnsmasq':
    ensure => 'running',
    enable => true,
    require => Package['dnsmasq'],
  }

  file { '/etc/dnsmasq.d/arroyo':
    ensure => 'file',
    source => 'puppet:///modules/arroyo/dnsmasq.conf',
    require => Package['dnsmasq'],
    notify => Service['dnsmasq'],
  }

  service { 'networking':
    ensure => 'running',
    enable => true,
  }

  file_line { 'local_resolve':
    line => 'prepend domain-name-servers 127.0.0.1;',
    path => '/etc/dhcp/dhclient.conf',
    require => Service['dnsmasq'],
    notify => Service['networking'],
  }

  /* Composer & Packages */

  $composer_path = '/usr/local/composer'
  $composer_command = "php $composer_path/composer.phar"

  file { $composer_path:
    ensure => 'directory',
  }

  exec { 'composer':
    command => 'curl -s http://getcomposer.org/installer | php',
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    creates => "$composer_path/composer.phar",
    cwd => $composer_path,
    require  => [
      Package['curl'],
      Package['php5-dev'],
      File['/usr/local/composer']
    ],
  }

  file { '/usr/local/bin/composer':
    ensure => 'link',
    target => "$composer_path/composer.phar",
    require => Exec['composer'],
  }

  file { "$composer_path/composer.json":
    ensure => 'file',
    source => 'puppet:///modules/arroyo/composer.json',
    require => Exec['composer'],
  }

  exec { 'composer_update':
    command => "$composer_command update",
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    environment => ["COMPOSER_HOME=$composer_path"],
    cwd => $composer_path,
    tries => 10,
    timeout => 20000,
    logoutput => true,
    returns => 0,
    require  => [
    File['/usr/local/composer/composer.json'],
      Exec['composer']
    ],
  }

  /* Drush */
  exec { "drush_init":
    command => "drush status",
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    require => [
      Exec['composer_update']
    ],
  }

  file { '/home/vagrant/.drush':
    owner => 'vagrant',
    group => 'vagrant',
    ensure => 'directory',
  }

  exec { 'drush_remake':
    user => 'vagrant',
    command => "drush dl drush_remake",
    environment => ["HOME=/home/vagrant"],
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    creates => "/home/vagrant/.drush/drush_remake",
    require => [
      Exec['drush_init']
    ],
  }

  exec { 'drush_registry_rebuild':
    user => 'vagrant',
    command => "drush dl registry_rebuild",
    environment => ["HOME=/home/vagrant"],
    path    => "/usr/local/bin/:/bin/:/usr/bin/",
    creates => "/home/vagrant/.drush/registry_rebuild",
    require => [
      Exec['drush_init']
    ],
  }

  exec { 'amix_vimrc':
    user => 'vagrant',
    command => 'git clone git://github.com/amix/vimrc.git /home/vagrant/.vim_runtime && sh /home/vagrant/.vim_runtime/install_awesome_vimrc.sh',
    path => "/usr/local/bin/:/bin/:/usr/bin/",
    creates => "/home/vagrant/.vim_runtime",
    require => [
      Package['git-core'],
      Package['vim'],
      Package['ctags']
    ],
  }

  exec { 'amix_vimrc_update':
    user => 'vagrant',
    command => 'git pull --rebase',
    cwd => '/home/vagrant/.vim_runtime',
    path => "/usr/local/bin/:/bin/:/usr/bin/",
    require => Exec['amix_vimrc']
  }

  file { "/home/vagrant/.drush/aliases.drushrc.php":
    ensure => 'present',
    owner => 'vagrant',
    group => 'vagrant',
    source => 'puppet:///modules/arroyo/aliases.drushrc.php',
    require => File['/home/vagrant/.drush'],
  }

  file { "/home/vagrant/.drush/drushrc.php":
    ensure => 'present',
    owner => 'vagrant',
    group => 'vagrant',
    source => 'puppet:///modules/arroyo/drushrc.php',
    require => File['/home/vagrant/.drush'],
  }

  class { 'ruby':
    ruby_package     => 'ruby1.9.1-full',
    rubygems_package => 'rubygems1.9.1',
    gems_version     => 'latest',
  }

  package { 'bundler':
    ensure => 'installed',
    provider => 'gem',
  }

  class { 'nodejs':
    version => 'stable',
  }

  package { 'grunt-cli':
    provider => 'npm',
    require => Class['nodejs'],
  }

  package { 'bower':
    provider => 'npm',
    require => Class['nodejs'],
  }
}
