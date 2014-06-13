package org.openmrs.module.oralhealth.extension.html;

import org.openmrs.module.web.extension.PatientDashboardTabExt;

public class OralHealthTab extends PatientDashboardTabExt 
{
	
	private String tabId = "oralHealth";
	
	/**
	 * privileges required for accessing the tab
	 * TODO apply access restrictions
	 */
	@Override
	public String getRequiredPrivilege() 
	{
		return "";
	}

	@Override
	public String getTabName() 
	{
		return "oralhealth.tabtitle";
	}

	@Override
	public String getTabId() 
	{
		return tabId;
	}

	@Override
	public String getPortletUrl() 
	{
		return "oralhealthHome";
	}

}
