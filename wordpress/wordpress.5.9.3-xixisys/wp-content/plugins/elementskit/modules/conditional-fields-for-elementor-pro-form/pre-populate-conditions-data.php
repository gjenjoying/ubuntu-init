<?php
namespace ElementsKit\Modules\Conditional_Fields_For_Elementor_Pro_Form;

class Pre_Populate_Conditions_Data{

    public function __construct() {
        // Call the function before the form render on front end
        add_action('elementor-pro/forms/pre_render', [$this, 'elementskit_conditional_field_for_pro_form_pre_render'], 10, 2);
	}

    /**
     * Pre render the condition data to the form as an attribute 
     */
    public function elementskit_conditional_field_for_pro_form_pre_render($instance, $form){

        $field_conditions = $this->get_field_conditions($instance);

        $enabled = false;
        if (!empty($field_conditions)) {
            $enabled = true;
            $form->add_render_attribute('wrapper', 'elementskit-field-conditions', wp_json_encode($field_conditions));
        }
    
        if ($enabled) {
    
            $field_ids = [];
            foreach ($instance['form_fields'] as $field) {
                $field_ids[] = $field['custom_id'];
            }
            $form->add_render_attribute('wrapper', 'elementskit-field-ids', wp_json_encode($field_ids));
    
        }

    }


    /**
     *  Populate the field conditions and put them into an array.
     */
    public function get_field_conditions($instance){
        $conditions = [];
        foreach ($instance['form_fields'] as $field) {
            if ($this->are_conditions_enabled($field)) {
                $conditions[] = array(
                    'id' => $field['custom_id'], 
                    'condition' => $this->join_lines_with_and( $field['form_fields_elementskit_condition_expressions'] ), 
                    'mode' => $field['form_fields_elementskit_condition_action']
                );
            }
        }
        return $conditions;
    }

    /**
     * Check if the condition is enabled on that field 
     */
    public function are_conditions_enabled($field) {
        $enabled = $field['form_fields_elementskit_condition_enabled'] === 'yes';
        return $enabled && !\preg_match('/^\\s*$/', $field['form_fields_elementskit_condition_expressions']);
    }


    /**
     * Join the lines with AND conditon
     */
    public function join_lines_with_and($expr) {

        $lines = \preg_split('/\\r\\n|\\r|\\n/', $expr);
        $lines = \array_filter($lines, function ($l) {
            return !\preg_match('/^\\s*$/', $l);
            // filter empty lines
        });
        return '(' . \implode(')&&(', $lines) . ')';
    
    }

}