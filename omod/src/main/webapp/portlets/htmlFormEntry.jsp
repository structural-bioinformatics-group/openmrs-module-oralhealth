<%@ include file="/WEB-INF/template/include.jsp" %>

<c:set var="OPENMRS_DO_NOT_SHOW_PATIENT_SET" scope="request" value="true"/>
<c:set var="pageFragment" value="${param.pageFragment != null && param.pageFragment}"/>
<c:set var="inPopup" value="${pageFragment || (param.inPopup != null && param.inPopup)}"/>

<c:if test="${not pageFragment}">
    <c:set var="DO_NOT_INCLUDE_JQUERY" value="true"/>
<c:choose>
<c:when test="${inPopup}">
<%@ include file="/WEB-INF/template/headerMinimal.jsp" %>
</c:when>
<c:otherwise>
<%@ include file="/WEB-INF/template/header.jsp" %>
</c:otherwise>
</c:choose>

<openmrs:htmlInclude file="/dwr/engine.js" />
<openmrs:htmlInclude file="/dwr/util.js" />
<openmrs:htmlInclude file="/dwr/interface/DWRHtmlFormEntryService.js" />
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/jquery-ui-1.8.17.custom.css" />
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/jquery-1.4.2.min.js" />
    <script type="text/javascript">
        $j = jQuery.noConflict();
    </script>
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/jquery-ui-1.8.17.custom.min.js" />
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/htmlFormEntry.js" />
<openmrs:htmlInclude file="/moduleResources/htmlformentry/htmlFormEntry.css" />
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/htmlForm.js" />
    <openmrs:htmlInclude file="/moduleResources/htmlformentry/handlebars.min.js" />
</c:if>

<script type="text/javascript">
var propertyAccessorInfo = new Array();

// individual forms can define their own functions to execute before a form validation or submission by adding them to these lists
// if any function returns false, no further functions are called and the validation or submission is cancelled
var beforeValidation = new Array(); // a list of functions that will be executed before the validation of a form
var beforeSubmit = new Array(); // a list of functions that will be executed before the submission of a form

// boolean to track whether or not jquery document ready function fired
var initInd = true;

   // booleans used to track whether we are in the process of submitted or discarding a formk
   var isSubmittingInd = false;
   var isDiscardingInd = false;

$j(document).ready(function() {
$j('#deleteButton').click(function() {
// display a "deleting form" message
$j('#confirmDeleteFormPopup').children("center").html('<spring:message code="htmlformentry.deletingForm"/>');

// do the post that does the actual delete
$j.post("<c:url value="/module/htmlformentry/deleteEncounter.form"/>",
{ encounterId: "${command.encounter.encounterId}",
htmlFormId: "${command.htmlFormId}",
returnUrl: "${command.returnUrlWithParameters}",
reason: $j('#deleteReason').val()
},
function(data) {
var url = "${command.returnUrlWithParameters}";
if (url == null || url == "") {
url = "${pageContext.request.contextPath}/patientDashboard.form?patientId=${command.patient.patientId}";
}
window.parent.location.href = url;
}
);
});

// triggered whenever any input with toggleDim attribute is changed. Currently, only supports
// checkbox style inputs.
$j('input[toggleDim]').change(function () {
            var target = $j(this).attr("toggleDim");
            if ($j(this).is(":checked")) {
                $j("#" + target + " :input").removeAttr('disabled');
                $j("#" + target).animate({opacity:1.0}, 0);
                restoreContainerInputs($j("#" + target));
            } else {
                $j("#" + target + " :input").attr('disabled', true);
                $j("#" + target).animate({opacity:0.5}, 100);
                clearContainerInputs($j("#" + target));
            }
        })
        .change();

// triggered whenever any input with toggleHide attribute is changed. Currently, only supports
// checkbox style inputs.
        $j('input[toggleHide]').change(function () {
            var target = $j(this).attr("toggleHide");
            if ($j(this).is(":checked")) {
                $j("#" + target).fadeIn();
                restoreContainerInputs($j("#" + target));
            } else {
                $j("#" + target).hide();
                clearContainerInputs($j("#" + target));
            }
        })
        .change();

        // triggered whenever any input widget on the page is changed
    $j(':input').change(function () {
$j(':input.has-changed-ind').val('true');
});

        // warn user that his/her changes will be lost if he/she leaves the page
$j(window).bind('beforeunload', function(){
var hasChangedInd = $j(':input.has-changed-ind').val();
if (hasChangedInd == 'true' && !isSubmittingInd && !isDiscardingInd) {
return '<spring:message code="htmlformentry.loseChangesWarning"/>';
}
});

// catch form submit button (not currently used)
        $j('form').submit(function() {
isSubmittingInd = true;
return true;
});

// catch when button with class submitButton is clicked (currently used)
$j(':input.submitButton').click(function() {
isSubmittingInd = true;
return true;
});

// catch when discard link clicked
$j('.html-form-entry-discard-changes').click(function() {
isDiscardingInd = true;
return true;
});

// indicates this function has completed
initInd = false;

//managing the id of the newly generated id's of dynamicAutocomplete widgets
$j('div .dynamicAutocomplete').each(function(index) {
var string=((this.id).split("_div",1))+"_hid";
if(!$j('#'+string).attr('value'))
$j('#'+this.id).data("count",0);
else
$j('#'+this.id).data("count",parseInt($j('#'+string).attr('value')));
});
//add button for dynamic autocomplete
$j(':button.addConceptButton').click(function() {
var string=(this.id).replace("_button","");
var conceptValue=$j('#'+string+'_hid').attr('value')
if($j('#'+string).css('color')=='green'){
var divId=string+"_div";
var spanid=string+'span_'+ $j('#'+divId).data("count");
var count= $j('#'+divId).data("count");
$j('#'+divId).data("count",++count);
$j('#'+string+'_hid').attr('value',$j('#'+divId).data("count"));
var hidId=spanid+'_hid';
var v='<span id="'+spanid+'"></br>'+$j('#'+string).val()+'<input id="'+hidId+'" class="autoCompleteHidden" type="hidden" name="'+hidId+'" value="'+conceptValue+'">';
var q='<input id="'+spanid+'_button" type="button" value="Remove" onClick="$j(\'#'+spanid+'\').remove();openmrs.htmlformentry.refresh(this.id)"></span>';
$j('#'+divId).append(v+q);
$j('#'+string).val('');
}
});
});

// clear toggle container's inputs but saves the input values until form is submitted/validated in case the user
// re-clicks the trigger checkbox. Note: These "saved" input values will be lost if the form fails validation on submission.
function clearContainerInputs($container) {
if (!initInd) {
$container.find('input:text, input:password, input:file, select, textarea').each( function() {
$j(this).data('origVal',this.value);
$j(this).val("");
});
$container.find('input:radio, input:checkbox').each( function() {
if ($j(this).is(":checked")) {
$j(this).data('origState','checked');
$j(this).removeAttr("checked");
} else {
$j(this).data('origState','unchecked');
}
});
}
}

// restores toggle container's inputs from the last time the trigger checkbox was unchecked
function restoreContainerInputs($container) {
if (!initInd) {
$container.find('input:text, input:password, input:file, select, textarea').each( function() {
$j(this).val($j(this).data('origVal'));
});
$container.find('input:radio, input:checkbox').each( function() {
if ($j(this).data('origState') == 'checked') {
$j(this).attr("checked", "checked");
} else {
$j(this).removeAttr("checked");
}
});
}
}

var tryingToSubmit = false;

function submitHtmlForm() {
if (!tryingToSubmit) {
tryingToSubmit = true;
DWRHtmlFormEntryService.checkIfLoggedIn(checkIfLoggedInAndErrorsCallback);
}
}

function findAndHighlightErrors(){
/* see if there are error fields */
var containError = false;
var ary = $j(".autoCompleteHidden");
$j.each(ary,function(index, value){
if(value.value == "ERROR"){
if(!containError){
alert("<spring:message code='htmlformentry.error.autoCompleteAnswerNotValid'/>");
var id = value.id;
id = id.substring(0,id.length-4);
$j("#"+id).focus();
}
containError=true;
}
});
return containError;
}

    function findOptionAutoCompleteErrors() {
        /* see if there are errors in option fields */
var containError = false;
var ary = $j(".optionAutoCompleteHidden");
$j.each(ary,function(index, value){
if(value.value == "ERROR"){
if(!containError){
alert("<spring:message code='htmlformentry.error.autoCompleteOptionNotValid'/>");
var id = value.id;
id = id.substring(0,id.length-4);
$j("#"+id).focus();
}
containError=true;
}
});
return containError;
    }

/*
It seems the logic of showAuthenticateDialog and
findAndHighlightErrors should be in the same callback function.
i.e. only authenticated user can see the error msg of
*/
function checkIfLoggedInAndErrorsCallback(isLoggedIn) {

var state_beforeValidation=true;

if (!isLoggedIn) {
showAuthenticateDialog();
}else{

// first call any beforeValidation functions that may have been defined by the html form
if (beforeValidation.length > 0){
for (var i=0, l = beforeValidation.length; i < l; i++){
if (state_beforeValidation){
var fncn=beforeValidation[i];	
state_beforeValidation=fncn.call(undefined);
}
else{
// forces the end of the loop
i=l;
}
}
}

// only do the validation if all the beforeValidationk functions returned "true"
if (state_beforeValidation) {
var anyErrors = findAndHighlightErrors();
                var optionSelectErrors = findOptionAutoCompleteErrors();

         if (anyErrors || optionSelectErrors) {
             tryingToSubmit = false;
             return;
         } else {
         doSubmitHtmlForm();
         }
}
            else {
                tryingToSubmit = false;
            }
}
}

function showAuthenticateDialog() {
$j('#passwordPopup').show();
tryingToSubmit = false;
}

function loginThenSubmitHtmlForm() {

$j('#passwordPopup').hide();
var username = $j('#passwordPopupUsername').val();
var password = $j('#passwordPopupPassword').val();
$j('#passwordPopupUsername').val('');
$j('#passwordPopupPassword').val('');
DWRHtmlFormEntryService.authenticate(username, password, submitHtmlForm);
}

function doSubmitHtmlForm() {

// first call any beforeSubmit functions that may have been defined by the form
var state_beforeSubmit=true;
if (beforeSubmit.length > 0){
for (var i=0, l = beforeSubmit.length; i < l; i++){
if (state_beforeSubmit){
var fncn=beforeSubmit[i];	
state_beforeSubmit=fncn();	
}
else{
// forces the end of the loop
i=l;
}
}
}

// only do the submit if all the beforeSubmit functions returned "true"
if (state_beforeSubmit){
var form = document.getElementById('htmlform');
form.submit();	
}
tryingToSubmit = false;
}

function handleDeleteButton() {
$j('#confirmDeleteFormPopup').show();
}

function cancelDeleteForm() {
$j('#confirmDeleteFormPopup').hide();
}


</script>

<div id="htmlFormEntryBanner">
<spring:message var="backMessage" code="htmlformentry.goBack"/>
<c:if test="${!inPopup && (command.context.mode == 'ENTER' || command.context.mode == 'EDIT')}">
<spring:message var="backMessage" code="htmlformentry.discard"/>
</c:if>
<div style="float: left" id="discardAndPrintDiv">
<c:if test="${!inPopup}">
<span id="discardLinkSpan"><a href="<c:choose><c:when test="${not empty command.returnUrlWithParameters}">${command.returnUrlWithParameters}</c:when><c:otherwise>${pageContext.request.contextPath}/patientDashboard.form?patientId=${command.patient.patientId}</c:otherwise></c:choose>" class="html-form-entry-discard-changes">${backMessage}</a></span> |
</c:if>
<span id="printLinkSpan"><a href="javascript:window.print();"><spring:message code="htmlformentry.print"/></a></span> &nbsp;<br/>
</div>
<div style="float:right">
<c:if test="${command.context.mode == 'VIEW'}">
<c:if test="${!inPopup}">
<openmrs:hasPrivilege privilege="Edit Encounters,Edit Observations">
<c:url var="editUrl" value="/module/htmlformentry/htmlFormEntry.form">
<c:forEach var="p" items="${param}">
<c:if test="${p.key != 'mode'}">
<c:param name="${p.key}" value="${p.value}"/>
</c:if>
</c:forEach>
<c:param name="mode" value="EDIT"/>
</c:url>
<a href="${editUrl}"><spring:message code="general.edit"/></a> |
</openmrs:hasPrivilege>
</c:if>
<openmrs:hasPrivilege privilege="Delete Encounters,Delete Observations">
<a onClick="handleDeleteButton()"><spring:message code="general.delete"/></a>
<div id="confirmDeleteFormPopup" style="position: absolute; z-axis: 1; right: 0px; background-color: #ffff00; border: 2px black solid; display: none; padding: 10px">
<center>
<spring:message code="htmlformentry.deleteReason"/>
<br/>
<textarea name="reason" id="deleteReason"></textarea>
<br/><br/>
<input type="button" value="<spring:message code="general.cancel"/>" onClick="cancelDeleteForm()"/>
&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" value="<spring:message code="general.delete"/>" id="deleteButton"/>
</center>
</div>
</openmrs:hasPrivilege>
</c:if>
</div>
<c:if test="${!inPopup}">
<b>
${command.patient.personName} |
<c:choose>
<c:when test="${not empty command.form}">
${command.form.name} (${command.form.encounterType.name})
</c:when>
<c:otherwise>
<c:if test="${not empty command.encounter}">
${command.encounter.form.name} (${command.encounter.encounterType.name})
</c:if>
</c:otherwise>
</c:choose>

|
<c:if test="${not empty command.encounter}">
<openmrs:formatDate date="${command.encounter.encounterDatetime}"/> | ${command.encounter.location.name}
</c:if>
<c:if test="${empty command.encounter}">
<spring:message code="htmlformentry.newForm"/>
</c:if>
</b>
</c:if>
</div>

<c:if test="${command.context.mode != 'VIEW'}">
<spring:hasBindErrors name="command">
<spring:message code="fix.error"/>
<div class="error">
<c:forEach items="${errors.allErrors}" var="error">
<spring:message code="${error.code}" text="${error.code}"/><br/>
</c:forEach>
</div>
<br />
</spring:hasBindErrors>
</c:if>

<c:if test="${command.context.mode != 'VIEW'}">
<form id="htmlform" method="post" onSubmit="submitHtmlForm(); return false;" enctype="multipart/form-data">
<input type="hidden" name="personId" value="${ command.patient.personId }"/>
<input type="hidden" name="htmlFormId" value="${ command.htmlFormId }"/>
<input type="hidden" name="formModifiedTimestamp" value="${ command.formModifiedTimestamp }"/>
<input type="hidden" name="encounterModifiedTimestamp" value="${ command.encounterModifiedTimestamp }"/>
<c:if test="${ not empty command.encounter }">
<input type="hidden" name="encounterId" value="${ command.encounter.encounterId }"/>
</c:if>
<input type="hidden" name="closeAfterSubmission" value="${param.closeAfterSubmission}"/>
<input type="hidden" name="hasChangedInd" class="has-changed-ind" value="${ command.hasChangedInd }" />
</c:if>

<c:if test="${command.context.guessingInd == 'true'}">
<div class="error">
<spring:message code="htmlformentry.form.reconstruct.warning" />
</div>
</c:if>

${command.htmlToDisplay}


                <table>
                        <tr>
                                <td>Date:</td>
                                <td><encounterDate/></td>
                        </tr>
                        <tr>
                                <td>Location:</td>
                                <td><encounterLocation/></td>
                        </tr>
                        <tr>
                                <td>Provider:</td>
                                <td><encounterProvider/></td>
                        </tr>
                </table>
<table style="border:none;">
<tbody>
<tr>
<td>



<table border="1" ; width="1050" >
					<tbody>
						<tr> <td>
                <span style="font-size:9px;">        DOCTOR NAME:    <textarea cols="15" rows="1"conceptId=""> </textarea>  </span>

                <span style="font-size:9px;">        <p>EXEMINATION DATE: <textarea cols="15" rows="1"conceptId=""> </textarea> </p> </span>

                 <span style="font-size:9px;">       <p>CITY:  <textarea cols="15" rows="1"conceptId=""> </textarea></p>    </span>





                        </td>


<td>
<span style="font-size:9px;">PATIENT NAME:  <textarea cols="15" rows="1"conceptId="6221"> </textarea></span>

<p><span style="font-size:9px;">BIRTHDATE: <textarea cols="10" rows="1" conceptId="6219"> </textarea></span>
	</p>
<p><span style="font-size:9px;">PLACE OF RESIDENCE: <textarea cols"15" rows="1" conceptId="6220"> </textarea></span>
	</p>
							</td>
<td>
<span style="font-size:9px;">SIGNATURE DOCTOR ______________
</span></td>
						</tr>
					</tbody>
				</table>






<table style="border:none">
<tbody>
<tr>
<td>
<table  border="1" height="200" width="647" >
					<tbody>
						<tr>
							<td colspan="4" height="20">
								<span style="font size:9px;"><h4>ORAL MUCOSA</h4> </span></td>
						</tr>

						<tr>
							<td>
								<span style="font-size:10px;">LIPS</span></td>
							<td>
								<a class="infobox" title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="30cd7f4c-4109-4b38-9a49-934ec51658c8" name="30cd7f4c-4109-4b38-9a49-934ec51658c8"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
							<td><span style="font-size:10px;">GUM</span></td>

							<td>
<a class="infobox" title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="30cd7f4c-4109-4b38-9a49-934ec51658c8"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>

						</tr>
						<tr>
							<td>
								<span style="font-size:10px;">HARD PALATE</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="db5fb77b-2176-4b1a-a90f-2b7eac047878"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
							<td>
								<span style="font-size:10px;">TONSIL</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="6209"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
						</tr>
						<tr>
							<td>
								<span style="font-size:10px;">SOFT PALATE</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="6210"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
							<td>
								<span style="font-size:10px;">TONGUE</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="5879b5d1-3f80-4d4f-af01-957463f0d253"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
						</tr>
						<tr>
							<td>
								<span style="font-size:10px;">UVULA</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="6212"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
							<td>
								<span style="font-size:10px;">OTHER NOTICES</span></td>
							<td>
								<a title="INFO: e.g. healthy, ill,..."><span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="6213"></textarea></span></a>

									<span style="font-size:10px;"></span>

							</td>
						</tr>
					</tbody>
				</table>

</td>
<td>






<table colspan="1" border="1" width="400" height="278">
<tbody><tr>

							<td colspan="2" height="20">
								<span style="font size:9px;"><h4>OTHER INFORMATION</h4></span></td>
						</tr>
						<tr>
							<td>
								<span style="font-size:10px;">KNOWN DISEASES</span></td>
							<td>
								<span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="4d5a928d-618d-4668-a11c-92a3e65f0a7b" id="known diseases"></textarea></span>

									<span style="font-size:10px;"></span>

								<p style="text-align: center;">
								</p>
							</td>
						</tr>
						<tr>
							<td>

									<span style="font-size:10px;">DRUGS</span>
							</td>
							<td>
								<span style="font-size:10px;"><textarea cols="17" rows="3" maxlength="20" conceptId="6131" id="drugs"></textarea></span>

									<span style="font-size:10px;"></span>

								<p style="text-align: center;">
								</p>
							</td>
						</tr>
						<tr>
							<td>

									<span style="font-size:10px;">SMOKING</span>
							</td>
							<td>
								<span style="font-size:10px;"><select conceptId="2e0124cb-1f65-41ce-a0f1-e1eaf93b667a" id="SMOKING">
                                <option>No</option><option>More than 15/d</option><option>Less than 15/d</option></select></span>
								<p>
									<span style="font-size:10px;"></span></p>

								<p style="text-align: center;">
								</p>


			</td></tr></tbody></table></td></tr></tbody></table>
</td></tr>
<tr><td width="540">



<table border="1" width="1050" ;>
	<tbody>
		<tr>
		<td colspan="17" height="20"><span style="font size:9px;"><h4>DENTAL STATUS</h4></span></td>

			</tr>



	<tr>
			<td>
				<a class="infobox" title="Periodontal Screening Index"><span style="font-size:10px;">PSI*</span></a></td>
			<td colspan="5" style="text-align: center;">
					<span style="font-size:10px;"><a title="PSI for teeth 18 to 14: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 18-14_</a><select conceptId="6124" id="treat_18-13" defaultValue="6119">
                    <option>0</option><option>1</option><option>2</option> <option>3</option><option>4</option></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td colspan="6" style="text-align: center;">
				<span style="font-size:10px;"><a title="PSI for teeth 13 to 23: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 13-23_</a><select conceptId="6125" id="treat_12-23" defaultValue="6119"><option>0</option><option>1</option><option>2</option> <option>3</option><option>4</option></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td colspan="5" style="text-align: center;">
				<span style="font-size:10px;"><a title="PSI for teeth 24 to 28: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 24-28_</a><select conceptId="6126" id="treat_24-28" defaultValue="6119"><option>0</option><option>1</option><option>2</option> <option>3</option><option>4</option></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>





</tr>


<tr>


<td>
				<p>
					<span style="font-size:10px;">TREATMENT</span></p>
			</td>
			<td>
				<a title="Choose for treatment for tooth 18: N=None, EX=Extraction, RCT=Root Canal Treatment, F=Filling"><span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="28aa690f-bf0d-4aa0-acee-c7fa4db1baeb" defaultValue="1101"><option>N</option><option>EX</option><option>RCT</option> <option>F</option> </select></span></a>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>

					<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="0eacc927-cf73-4d12-855d-1ffd9f584295" id="treat_17" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                             </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="2ba433a4-6ed6-4f58-9ee5-170119956be0" id="treat_16" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                    </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="49bbc6b4-cdbe-4b10-a577-a6b782038fcc" id="treat_15" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                   </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="70ced3fc-45ea-4d71-98c7-b33896d93920" id="treat_14" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                  </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="1797a73e-05c6-4db2-bf0e-c0e1c021606c" id="treat_13" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="7df30420-7772-430f-98d8-e44d61e47646" id="treat_12" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                               </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="29a91b7a-886e-4c10-9900-1b71af280e61" id="treat_11" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="0b25ef0c-166f-46f6-8786-6374e8ff5f10" id="treat_21" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                 </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="550c1cf6-212d-4505-a710-84a75d810f9e" id="treat_22" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                   </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="e0b3fe61-f0cb-4774-b74d-e1b0befc9c5f" id="treat_23" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                           </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="73bd494c-5815-4f65-a5de-2fc509cb3573" id="treat_24" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                           </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="98a609ee-43d9-478d-9013-e7f908116673" id="treat_25" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                     </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="109e7d8f-32bf-4528-9131-fb278541f472" id="treat_26" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                    </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="63d16ed8-723b-40f2-9fba-acd88c16437b" id="treat_27" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>    </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="bbbc1536-933e-4794-adca-ac8643298295" id="treat_28" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                  </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
		</tr>







		<tr>

		<td>
				<p>
					<span style="font-size:10px;">STATUS</span></p>
			</td>
			<td>
				<a title="Choose for tooth 18: H=Health, D=Decayed, F=Filled, M=Missing"><span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="e7eb65cc-b80e-43c2-84c9-9554c2b06863" id="1.8" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option></select></span></a>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="42c03f3b-89b8-4656-bbe1-ae966b9d88d2" id="1.7" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="fd743910-f077-4b92-81eb-82f6dab03472" id="1.6" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="d5f9a5c8-112b-4973-b9c3-1706f40d62dd" id="1.5" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="972518e3-fe62-4cf6-90f9-72609de97220" id="1.4" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="dccde639-4737-4523-bc06-e3d29d1a3c63" id="1.3" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="bf3e73c5-9b05-459b-9632-1e5ce48cb841" id="1.2" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="a37aa7c4-8174-4e3e-a3c2-60611dced4c5" id="1.1" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="17dbcefd-b0ae-4d48-a5b6-c8ced76c201e" id="2.1" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="8e334b8a-30b5-4437-a95d-f561899cf090" id="2.2" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="a00186b0-0365-4b99-a7ad-978bfa814858" id="2.3" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="9be2e5cc-2339-4bb1-98d3-ab371001f26d" id="2.4" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="b95ea533-10ea-415e-8ac6-b0151371aad6" id="2.5" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="716e0404-4303-452f-9717-25a4d02a663b" id="2.6" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="db414ca8-7467-4a0f-b048-a210881b87ed" id="2.7" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="5d945834-b45b-4461-b693-3d93f5239f85" id="2.8" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
		</tr>
		<tr>
			<td>
				<span style="font-size:10px;">DECIDUOUS TEETH</span></td>

			<td style="border-right-style:none;">
			</td>
			<td style="border-left-style:none;border-right-style:none;">
			</td>
			<td  style="border-left-style:none;">
			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">55</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">54</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">53</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">52</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center; border-right-width: medium; border-style:solid;">

					<span style="font-size:10px;">51</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">61</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">62</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">63</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">64</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">65</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="c439524b-5e37-4a9c-8825-e9264b31b6db" style="checkbox"></span>


			</td>
			<td style="border-right-color:#FFFFFF;">
			</td>
			<td style="border-right-color:#FFFFFF;">
			</td>
			<td>
			</td>
		</tr>
		<tr>
			<td rowspan="2">
				<span style="font-size:10px;">PERMANENT TEETH</span></td>



			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">18</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<p style="text-align: center;">
					<span style="font-size:10px;">17</span></p>
			</td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<p style="text-align: center;">
					<span style="font-size:10px;">16</span></p>
			</td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<p style="text-align: center;">
					<span style="font-size:10px;">15</span></p>
			</td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<p style="text-align: center;">
					<span style="font-size:10px;">14</span></p>
			</td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">13</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">12</span></td>
			<td style="text-align: center; border-bottom-width: medium;  border-style:solid ; border-right-width:medium; border-style:solid">
				<span style="font-size:10px;">11</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">21</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">22</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">23</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">24</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">25</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">26</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">27</span></td>
			<td style="text-align: center; border-bottom-width: medium; border-style:solid ; ">
				<span style="font-size:10px;">28</span></td>
		</tr>
		<tr>
			<td style="text-align: center;">
				<span style="font-size:10px;">48</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">47</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">46</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">45</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">44</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">43</span></td>
			<td>
				<p style="text-align: center;">
					<span style="font-size:10px;">42</span></p>
			</td>
			<td style="text-align: center; border-right-width: medium; border-style:solid;">
				<span style="font-size:10px;">41</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">31</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">32</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">33</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">34</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">35</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">36</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">37</span></td>
			<td style="text-align: center;">
				<span style="font-size:10px;">38</span></td>
		</tr>

		<tr>
			<td>
				<span style="font-size:10px;">DECIDUOUS TEETH</span></td>
			<td style="border-right-style:none;">
			</td>
			<td style="border-left-style:none;border-right-style:none;">
			</td>
			<td  style="border-left-style:none;">
			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">85</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">84</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">83</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">82</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center; border-right-width:medium; border-style: solid">

					<span style="font-size:10px;">81</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">71</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">72</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">73</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">74</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>
			<td style="text-align: center;">

					<span style="font-size:10px;">75</span><br/>

					<span style="font-size:10px;"><input type="checkbox" name="Zahlmethode" value="" answerConceptId="df9a75f8-af51-11e3-9792-0c84dcf2d904" answerLabel="" conceptId="0b3863f1-d2cb-4d0c-ae94-0317883651be" style="checkbox"></span>


			</td>


			<td style="border-right-style:none;">
			</td>
			<td style="border-left-style:none;border-right-style:none;">
			</td>
			<td  style="border-left-style:none;">
			</td>
		</tr>




		<tr>
<td>
<p>
					<span style="font-size:10px;">STATUS</span></p>
			</td>
			<td>
				<span style="font-size:10px;"><a title="Choose for tooth 48: H=Health, D=Decayed, F=Filled, M=Missing"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="61ac6b5b-8f5e-4042-a049-4d2f98542c85" id="4.8" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></a></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="cdd9a1cb-2999-4602-b8b6-270d98e661a0" id="4.7" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="d42ce879-02de-4edf-96db-7a71b3c9c7b4" id="4.6" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="b6afa216-371e-46ee-a67a-a22c4471b8b9" id="4.5" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="bb059d69-a78c-40f6-b18c-6e2724fa7a86" id="4.4" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="875b2e51-2c33-4b1a-898f-1f2cc3c35695" id="4.3" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="2f59d155-e11c-46a4-ba88-685d464097d1" id="4.2" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="db05359e-7177-453d-8b57-ca11cf099bb4" id="4.1" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="bbbf29c1-fe9d-44a7-8649-8592291d79cd" id="3.1" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="b7d60bfa-5321-4fe6-bc18-14efada64b1c" id="3.2" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="64a2375d-2846-4d62-bafa-b5164d22f09e" id="3.3" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="a2269d63-d7df-41ab-89f9-4bb7e4acc228" id="3.4" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="ca9d360c-39cb-43b9-9ab2-0a3991496e3a" id="3.5" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="a4dc3ec8-2dd9-4d9a-9cc8-a14f1df0b605" id="3.6" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="6a4700d8-c3c4-47c9-aa44-8607a9f5c8b8" id="3.7" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="6218,6155,6157,6156" answerLabels="H,D,M,F" conceptId="da0442ea-c13b-4dd4-9898-028618b612fa" id="3.8" defaultValue="6218"><option>H</option><option>D</option><option>F</option><option>M</option> </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			</tr>


		<tr>
			<td>
				<p>
					<span style="font-size:10px;">TREATMENT</span></p>
			</td>
			<td>
				<span style="font-size:10px;"><a title="Choose for treatment for tooth 48: N=None, EX=Extraction, RCT=Root Canal Treatment, F=Filling"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="6dfc296c-a5cb-465a-9c16-7d4c9a2996e9" id="treat_48" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>         </select></a></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="38aff031-93cc-4199-9a22-11d7e6a14c11" id="treat_47" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                     </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="19347f6e-bfb9-4414-a8ff-b4726f83cc84" id="treat_46" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                                    </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="8fdae0ac-46fa-4d29-bc17-9e4f2db75add" id="treat_45" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                               </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="6ce45845-4827-488a-91da-f3558996271f" id="treat_44" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                           </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="dc9cc754-8330-421d-9ebb-2662f5b9fb3a" id="treat_43" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>                                   </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="e40ef50f-234a-4eb1-9dad-8c3a9fbf2fd3" id="treat_42" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                      </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="9b65b97f-a4d8-4eb8-883f-84a1a01e0683" id="treat_41" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                     </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="48772ca5-5257-4e58-b501-dcc453f2d8c3" id="treat_31" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                            </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="b0b26c80-5eeb-4375-8222-c6214abf0c3a" id="treat_32" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                     </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="cf928fdc-c44b-4266-8762-d3c2c7ee3fcc" id="treat_33" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                  </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="902f88b4-de1b-424c-89d7-183d778fc72c" id="treat_34" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                   </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="016b3d34-683e-4040-ae93-de7e1a107b1b" id="treat_35" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                     </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="fcfa4c6f-60a0-47e9-87d4-9558d7822a46" id="treat_36" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                 </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="3edb6c35-cd13-4cce-bc7b-c5ecc922ed07" id="treat_37" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                      </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td>
				<span style="font-size:10px;"><select answerConceptIds="1101,6100,6101,6102" answerLabels="N,EX,RCT,F" conceptId="acb50e0b-804c-46c7-8bd5-6d4d5959f5ff" id="treat_38" defaultValue="1101"> <option>N</option><option>EX</option><option>RCT</option> <option>F</option>
                   </select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
		</tr>

			<tr>
			<td>
				<span style="font-size:10px;">PSI*</span></td>
			<td colspan="5" style="text-align: center;">
				<span style="font-size:10px;"><a title="PSI for teeth 48 to 44: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 48-44_</a><select conceptId="6127" id="treat_48-44" defaultValue="6119"></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td colspan="6" style="text-align: center;">
				<span style="font-size:10px;"><a title="PSI for teeth 43 to 33: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 43-33_</a><select conceptId="6128" id="treat_43-33" defaultValue="6119"></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
			<td colspan="5" style="text-align: center;">
				<span style="font-size:10px;"><a title="PSI for teeth 34 to 38: Code 0(GOOD/HEALTHY)... Code4(BAD/ILL)">PSI 34-38_</a><select conceptId="6129" id="treat_34-38" defaultValue="6119"></select></span>
				<p>
					<span style="font-size:10px;"></span></p>

			</td>
		</tr>




		<tr>
<td style="border-top-width:medium; border-style: solid;" colspan="2"><span style="font size:9px;"><h4>LEGEND</h4></span></td>
<td style="border-top-width:medium; border-style: solid;" colspan="5"><span style="font-size:8px;"><h5>Status of tooth:</h5><span style="font-size:8px;"> Choose H=Healthy, D=Decayed, M=Missing, F=Filled </span></span></td>

<td style="border-top-width:medium; border-style: solid;" colspan="5"><span style="font-size:8px;"><h5>Treatment for tooth:</h5><span style="font-size:8px;"> choose N=None, EX= Extraction, RCT= Root Canal Treatment, F=Filling</span></span></td>


<td style="border-top-width:medium; border-style: solid;" colspan="5"><span style="font-size:8px;"><h5>PSI</h5> <span style="font-size:8px;">Periodontal Screening Index= Code 0 (healthy) ... Code 4 (ill)</span></span></td>

</tr>

	</tbody>
</table>
</td>
</tr>
</tbody>
</table>
	
		<button onclick="myFunction()">Print this page</button>

		<script>
				function myFunction() {
  									  window.print();
															}
														</script>

 <input id="submit" type="button" value="Submit" />

<!--<input type="button" value="Submit" onClick="loginThenSubmitHtmlForm()"/>-->


<c:if test="${not empty command.fieldAccessorJavascript}">
<script type="text/javascript">
${command.fieldAccessorJavascript}
</script>
</c:if>
<c:if test="${not empty command.setLastSubmissionFieldsJavascript || not empty command.lastSubmissionErrorJavascript}">
<script type="text/javascript">
$j(document).ready( function() {
${command.setLastSubmissionFieldsJavascript}
${command.lastSubmissionErrorJavascript}

$j('input[toggleDim]:not(:checked)').each(function () {
var target = $j(this).attr("toggleDim");
$j("#" + target + " :input").attr('disabled', true);
$j("#" + target).animate({opacity:0.5}, 100);
});

$j('input[toggleDim]:checked').each(function () {
var target = $j(this).attr("toggleDim");
$j("#" + target + " :input").removeAttr('disabled');
$j("#" + target).animate({opacity:1.0}, 0);
});

$j('input[toggleHide]:not(:checked)').each(function () {
var target = $j(this).attr("toggleHide");
$j("#" + target).hide();
});

$j('input[toggleHide]:checked').each(function () {
var target = $j(this).attr("toggleHide");
$j("#" + target).fadeIn();
});

});
</script>
</c:if>

<c:if test="${!pageFragment}">
<c:choose>
<c:when test="${inPopup}">
<%@ include file="/WEB-INF/template/footerMinimal.jsp" %>
</c:when>
<c:otherwise>
<%@ include file="/WEB-INF/template/footer.jsp" %>
</c:otherwise>
</c:choose>
</c:if>