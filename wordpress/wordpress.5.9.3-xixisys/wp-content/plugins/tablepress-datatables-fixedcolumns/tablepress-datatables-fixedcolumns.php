<?php
/*
Plugin Name: TablePress Extension: DataTables FixedColumns
Plugin URI: https://tablepress.org/extensions/datatables-fixedcolumns/
Description: Extension for TablePress to add the DataTables FixedColumns functionality
Version: 1.7
Author: Tobias Bäthge
Author URI: https://tobias.baethge.com/
*/

/*
 * See http://datatables.net/extensions/fixedcolumns/
 */

/* Shortcode:
 * [table id=1 datatables_fixedcolumns=left|right|both /]
 * or
 * [table id=1 datatables_fixedcolumns_left_columns=2 datatables_fixedcolumns_right_columns=3 /]
 */

// Prohibit direct script loading.
defined( 'ABSPATH' ) || die( 'No direct script access allowed!' );

// Init TablePress_DataTables_FixedColumns.
add_action( 'tablepress_run', array( 'TablePress_DataTables_FixedColumns', 'init' ) );
TablePress_DataTables_FixedColumns::init_update_checker();

/**
 * TablePress Extension: DataTables FixedColumns
 * @author Tobias Bäthge
 * @since 1.2
 */
class TablePress_DataTables_FixedColumns {

	/**
	 * Plugin slug.
	 *
	 * @var string
	 * @since 1.2
	 */
	protected static $slug = 'tablepress-datatables-fixedcolumns';

	/**
	 * Plugin version.
	 *
	 * @var string
	 * @since 1.2
	 */
	protected static $version = '1.7';

	/**
	 * Instance of the Plugin Update Checker class.
	 *
	 * @var PluginUpdateChecker
	 * @since 1.2
	 */
	protected static $plugin_update_checker;

	/**
	 * Initialize the plugin by registering necessary plugin filters and actions.
	 *
	 * @since 1.2
	 */
	public static function init() {
		add_filter( 'tablepress_shortcode_table_default_shortcode_atts', array( __CLASS__, 'shortcode_table_default_shortcode_atts' ) );
		add_filter( 'tablepress_table_js_options', array( __CLASS__, 'table_js_options' ), 10, 3 );
		add_filter( 'tablepress_datatables_parameters', array( __CLASS__, 'datatables_parameters' ), 10, 4 );
	}

	/**
	 * Load and initialize the plugin update checker.
	 *
	 * @since 1.2
	 */
	public static function init_update_checker() {
		require_once dirname( __FILE__ ) . '/libraries/plugin-update-checker.php';
		self::$plugin_update_checker = PucFactory::buildUpdateChecker(
			'https://tablepress.org/downloads/extensions/update-check/' . self::$slug . '.json',
			__FILE__,
			self::$slug
		);
	}

	/**
	 * Add "datatables_fixedcolumns" and related parameters to the [table /] Shortcode.
	 *
	 * @since 1.2
	 *
	 * @param array $default_atts Default attributes for the TablePress [table /] Shortcode.
	 * @return array Extended attributes for the Shortcode.
	 */
	public static function shortcode_table_default_shortcode_atts( $default_atts ) {
		$default_atts['datatables_fixedcolumns'] = '';
		$default_atts['datatables_fixedcolumns_left_columns'] = 0;
		$default_atts['datatables_fixedcolumns_right_columns'] = 0;
		return $default_atts;
	}

	/**
	 * Pass configuration from Shortcode parameters to JavaScript arguments.
	 *
	 * @since 1.2
	 *
	 * @param array  $js_options     Current JS options.
	 * @param string $table_id       Table ID.
	 * @param array  $render_options Render Options.
	 * @return array Modified JS options.
	 */
	public static function table_js_options( $js_options, $table_id, $render_options ) {
		$js_options['datatables_fixedcolumns'] = strtolower( $render_options['datatables_fixedcolumns'] );
		$js_options['datatables_fixedcolumns_left_columns'] = absint( $render_options['datatables_fixedcolumns_left_columns'] );
		$js_options['datatables_fixedcolumns_right_columns'] = absint( $render_options['datatables_fixedcolumns_right_columns'] );

		/*
		 * Convert shortcut parameter value to detailed parameter values.
		 * The conversion is necessary for BC reasons, as previous versions supported a value like "right,left".
		 */
		if ( '' !== $js_options['datatables_fixedcolumns'] ) {
			// Convert the "both" shortcude to "left" and "right".
			$js_options['datatables_fixedcolumns'] = str_replace( 'both', 'left,right', $js_options['datatables_fixedcolumns'] );
			$fixedcolumns = explode( ',', $js_options['datatables_fixedcolumns'] );
			foreach ( $fixedcolumns as $column ) {
				if ( 'left' === $column ) {
					$js_options['datatables_fixedcolumns_left_columns'] = 1;
				} elseif ( 'right' === $column ) {
					$js_options['datatables_fixedcolumns_right_columns'] = 1;
				}
			}
		}

		// Change parameters and register files if at least one column is fixed.
		if ( $js_options['datatables_fixedcolumns_left_columns'] > 0 || $js_options['datatables_fixedcolumns_right_columns'] > 0 ) {
			// Horizontal Scrolling is mandatatory for the FixedColumns functionality.
			$js_options['datatables_scrollx'] = true;

			// Register the JS files.
			$suffix = ( defined( 'SCRIPT_DEBUG' ) && SCRIPT_DEBUG ) ? '' : '.min';
			$url = plugins_url( "js/dataTables.fixedColumns{$suffix}.js", __FILE__ );
			wp_enqueue_script( self::$slug, $url, array( 'tablepress-datatables' ), self::$version, true );

			// Add the common filter that adds JS for all calls on the page.
			if ( ! has_filter( 'tablepress_all_datatables_commands', array( __CLASS__, 'all_datatables_commands' ) ) ) {
				add_filter( 'tablepress_all_datatables_commands', array( __CLASS__, 'all_datatables_commands' ) );
			}
		}

		return $js_options;
	}

	/**
	 * Evaluate JS parameters and convert them to DataTables parameters.
	 *
	 * @since 1.2
	 *
	 * @param array  $parameters DataTables parameters.
	 * @param string $table_id   Table ID.
	 * @param string $html_id    HTML ID of the table.
	 * @param array  $js_options JS options for DataTables.
	 * @return array Extended DataTables parameters.
	 */
	public static function datatables_parameters( $parameters, $table_id, $html_id, $js_options ) {
		// Bail out early if no column is fixed.
		if ( 0 === $js_options['datatables_fixedcolumns_left_columns'] && 0 === $js_options['datatables_fixedcolumns_right_columns'] ) {
			return $parameters;
		}

		// Construct the DataTables FixedColumns config parameter.
		$parameters['fixedColumns'] = array();
		// The number of fixed columns on the left only needs to be set if changing the default of 1.
		if ( 1 !== $js_options['datatables_fixedcolumns_left_columns'] ) {
			$parameters['fixedColumns'][] = "\"leftColumns\":{$js_options['datatables_fixedcolumns_left_columns']}";
		}
		// The number of fixed columns on the right only needs to be set if changing the default of 0.
		if ( 0 !== $js_options['datatables_fixedcolumns_right_columns'] ) {
			$parameters['fixedColumns'][] = "\"rightColumns\":{$js_options['datatables_fixedcolumns_right_columns']}";
		}
		$parameters['fixedColumns'] = '"fixedColumns":{' . implode( ',', $parameters['fixedColumns'] ) . '}';

		return $parameters;
	}

	/**
	 * Add jQuery code that adds the necessary CSS for the Extension, instead of  loading that CSS from a file on all pages.
	 *
	 * @since 1.2
	 *
	 * @param array $commands The JS commands for the DataTables JS library.
	 * @return array Modified JS commands for the DataTables JS library.
	 */
	public static function all_datatables_commands( $commands ) {
		$commands = "$('head').append('<style>.DTFC_LeftBodyWrapper .tablepress thead th:after,.DTFC_RightBodyWrapper .tablepress thead th:after{content:\"\";}table.DTFC_Cloned thead,table.DTFC_Cloned tfoot,div.DTFC_Blocker{background-color:#fff}div.DTFC_LeftWrapper table.dataTable,div.DTFC_RightWrapper table.dataTable{margin-bottom:0;z-index:2}div.DTFC_LeftWrapper table.dataTable.no-footer,div.DTFC_RightWrapper table.dataTable.no-footer{border-bottom:none}</style>');\n" . $commands;
		return $commands;
	}

} // class TablePress_DataTables_FixedColumns
