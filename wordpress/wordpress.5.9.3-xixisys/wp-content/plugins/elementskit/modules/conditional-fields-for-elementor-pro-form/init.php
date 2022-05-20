<?php
namespace ElementsKit\Modules\Conditional_Fields_For_Elementor_Pro_Form;

defined( 'ABSPATH' ) || exit;

class Init {
    private $dir;
    private $url;

    public function __construct(){

		if(!class_exists('\ElementorPro\Core\App\App' ) ){
			return;
		}

        // get current directory path
        $this->dir = dirname(__FILE__) . '/';

        // get current module's url
		$this->url = \ElementsKit::plugin_url() . 'modules/conditional-fields-for-elementor-pro-form/';
		
		// enqueue scripts
		add_action( 'elementor/frontend/after_enqueue_scripts', [ $this, 'enqueue_scripts' ] );

		// include all necessary files
		$this->include_files();

		// // calling the sticky controls
		new \Elementor\ElementsKit_Extends_Form_Controls_For_Conditional_Fields();
		new Pre_Populate_Conditions_Data();
        
	}
	
	public function include_files(){
		include $this->dir . 'extend-form-controls.php';
		include $this->dir . 'pre-populate-conditions-data.php';
	}

	public function enqueue_scripts(){
		wp_enqueue_script( 'elementskit-conditional-fields', $this->url . 'assets/js/elementskit-conditional-fields.js', array( 'jquery', 'elementor-frontend' ), \ElementsKit::version(), true );
	}
}