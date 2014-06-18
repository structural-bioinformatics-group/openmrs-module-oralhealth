package org.openmrs.module.oralhealth.web.controller;

import org.openmrs.Obs;
import org.openmrs.api.context.Context;
import org.openmrs.web.controller.PortletController;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

//@Controller
//@RequestMapping("**/oralhealthHome")
public class OralHealthTabPortletController extends PortletController 
{
	public void processForm(@RequestParam(required=false, value="patientId") String patientId, ModelMap model)
	{
		model.addAttribute("patientNum", patientId);
	}
}
