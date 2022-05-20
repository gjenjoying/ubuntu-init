<?php
namespace Elementor;


use ElementorPro\Plugin;
use Elementor\Controls_Manager;

class ElementsKit_Extends_Form_Controls_For_Conditional_Fields{

    public function __construct() {

        add_action('elementor/element/form/section_form_fields/before_section_end', [ $this, 'elementskit_conditional_fields_control_pro_forms' ]);
	}
    
    /**
     * That function will render the field control inside elementor pro form fields inside a tab
     */
	public function elementskit_conditional_fields_control_pro_forms($widget) {
        
        $elementor = Plugin::elementor();
        $control_data = $elementor->controls_manager->get_control_from_stack($widget->get_unique_name(), 'form_fields');
        if (is_wp_error($control_data)) {
            return;
        }
    
        $field_controls = [
            'form_fields_elementskit_conditions_tab' => [
                'type' => 'tab', 
                'tab' => 'conditions', 
                'label' => __('Conditions', 'elementskit'), 
                'conditions' => [
                    'terms' => [
                        [
                            'name' => 'field_type', 
                            'operator' => '!in', 
                            'value' => ['hidden', 'step']
                        ]
                    ]
                ], 
                'tabs_wrapper' => 'form_fields_tabs', 
                'name' => 'form_fields_elementskit_conditions_tab'
            ], 
            'form_fields_elementskit_condition_enabled' => [
                'name' => 'form_fields_elementskit_condition_enabled', 
                'label' => __('Enable Conditions', 'elementskit'), 
                'type' => Controls_Manager::SWITCHER, 
                'label_on' => 'Yes', 
                'label_off' => 'No',
                'default' => 'No', 
                'tab' => 'conditions', 
                'tabs_wrapper' => 'form_fields_tabs', 
                'inner_tab' => 'form_fields_elementskit_conditions_tab'
            ],
            'form_fields_elementskit_condition_action' => [
                'name' => 'form_fields_elementskit_condition_action', 
                'label' => __('Enable Action', 'elementskit'), 
                'type' => Controls_Manager::SELECT, 
                'default' => 'show-if',
                'options' => [
                    'show-if'  => esc_html__( 'Show If', 'elementskit' ),
                    'hide-if' => esc_html__( 'Hide If', 'elementskit' ),
                ],
                'condition' => [
                    'form_fields_elementskit_condition_enabled' => 'yes'
                ],
                'tab' => 'conditions', 
                'tabs_wrapper' => 'form_fields_tabs', 
                'inner_tab' => 'form_fields_elementskit_conditions_tab'
            ],
            'form_fields_elementskit_condition_expressions' => [
                'name' => 'form_fields_elementskit_condition_expressions', 
                'type' => Controls_Manager::TEXTAREA, 
                'label' => __('Conditions Expressions', 'elementskit'), 
                'description' => __('Please enter one condition per line. All conditions per line will be with AND relation and if you want to use OR relation then just put || between the conditions in same line.', 'elementskit'), 
                'placeholder' => "name == 'John'", 
                'condition' => [
                    'form_fields_elementskit_condition_enabled' => 'yes'
                ], 
                'tab' => 'con', 
                'tabs_wrapper' => 'form_fields_tabs', 
                'inner_tab' => 'form_fields_elementskit_conditions_tab'
            ]
        ];
    
        /**
         * Merging the old controls with custom controls
         * */
        $control_data['fields'] = \array_merge($control_data['fields'], $field_controls);
        $widget->update_control('form_fields', $control_data);


	}
}