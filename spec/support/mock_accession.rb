# frozen_string_literal: true

module MockAccession
  Response = Struct.new(:code, :body)

  def successful_accession_response
    # Constructed using an example from the TEST service of a successful response:
    Response.new(
      200,
      '<?xml version="1.0" encoding="UTF-8"?>
       <?xml-stylesheet type="text/xsl" href="receipt.xsl"?>
       <RECEIPT receiptDate="2019-10-04T11:17:32.518+01:00" submissionFile="submission_file20191004-3135-xubuyl" success="true">
         <SAMPLE accession="ERS3798841" alias="58db740e-e5eb-11e9-9a6d-38f9d3dee0d3" status="PRIVATE" holdUntilDate="2021-10-04+01:00">
              <EXT_ID accession="SAMEA5996033" type="biosample"/>
         </SAMPLE>
         <SUBMISSION accession="ERA2158715" alias="58db740e-e5eb-11e9-9a6d-38f9d3dee0d3-2019-10-04T10:17:32Z"/>
         <MESSAGES>
              <INFO>All objects in this submission are set to private status (HOLD).</INFO>
              <INFO>Submission has been committed.</INFO>
              <INFO>This submission is a TEST submission and will be discarded within 24 hours</INFO>
         </MESSAGES>
         <ACTIONS>ADD</ACTIONS>
         <ACTIONS>HOLD</ACTIONS>
       </RECEIPT>'
    )
  end

  def failed_accession_response
    # Constructed using an example from the TEST service of a failed response:
    Response.new(
      200,
      '<?xml version="1.0" encoding="UTF-8"?>
       <?xml-stylesheet type="text/xsl" href="receipt.xsl"?>
       <RECEIPT receiptDate="2019-10-04T11:15:27.000+01:00" submissionFile="submission_file20191004-3135-1j8wryl" success="false">
         <SAMPLE alias="9bbc15b0-e5f2-11e9-b45f-38f9d3dee0d3" status="PRIVATE" holdUntilDate="2021-10-04+01:00"/>
         <SUBMISSION alias="9bbc15b0-e5f2-11e9-b45f-38f9d3dee0d3-2019-10-04T10:15:26Z"/>
         <MESSAGES>
              <ERROR>Error 1</ERROR>
              <ERROR>Error 2</ERROR>
              <INFO>Submission has been rolled back.</INFO>
              <INFO>This submission is a TEST submission and will be discarded within 24 hours</INFO>
         </MESSAGES>
         <ACTIONS>ADD</ACTIONS>
         <ACTIONS>HOLD</ACTIONS>
       </RECEIPT>'
    )
  end

  module_function :successful_accession_response, :failed_accession_response
end
