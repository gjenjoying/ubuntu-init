<?php
// 不要轻易改动此模板文件
// 注意！wp-config-example 中涉及到的 AUTH_KEY 等值，与 wordpress.5.9.3-xixisys.sql、wordpress.5.9.3-xixisys-initial.sql 中存的一致
// 后续如果要换 wordpress.5.9.3-xixisys.sql 这些sql，一定要从 wordpress.5.9.3-xixisys-initial.sql 重新配置一份，再改动，再保存到新的 wordpress.5.9.3-xixisys.sql
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', '{{dbName}}' );

/** Database username */
define( 'DB_USER', '{{dbWordpressUser}}' );

/** Database password */
define( 'DB_PASSWORD', '{{dbWordpressPassword}}' );

/** Database hostname */
define( 'DB_HOST', 'localhost' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'U2I_7X/`MoBKHaFQpH-bV7sHsa&bx.PM~d7ZiY7V8@&RPr`6zDI*p9,Uf?_57$8A' );
define( 'SECURE_AUTH_KEY',  '0sgi@OgscB)Nkpki}IMm<aCaoIh>`@fdp/]<f&]9cN6ZPtWKJQyQW{IrMV|nf,+,' );
define( 'LOGGED_IN_KEY',    'Fw4u&`9M@IJz$oo NB7,Un+i~}&IsKw~Zh(vA%K!$u}|}lTAf=(4?LA((KuQ?KV?' );
define( 'NONCE_KEY',        '&<#.57^?eD?51:9Dr>bjm+F=XJZ&lxupo=_6M=T|`?PX]f|7 :tt!B{V?7QK{`IK' );
define( 'AUTH_SALT',        'X!P8d%np?*tML,h0Z&oXtbi=$n.<E=ao@Xw+/vxCY_sa6xJe!)yAYB_nTb=&^U2q' );
define( 'SECURE_AUTH_SALT', 'enU5aGsnMS>axOl}<wy?6vQy5n1AFxd+cuX n|)Kfq G.kPi{n=_lzE2%EL?kfSO' );
define( 'LOGGED_IN_SALT',   '-T68@Pd!@!-]$!L[GdWEW5wWv ]$+}e#d&pEZv*Gr+S[LhuQWMA<8ZB/WdV;ro#}' );
define( 'NONCE_SALT',       'Uie^N8<x7TABe~iWcbCD /J)Dk[6Swp[V~F<N_[I%0bKoZ-*e!Ax1$i1JOlG_*78' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
