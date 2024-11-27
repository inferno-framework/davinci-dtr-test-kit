module DaVinciDTRTestKit
  module MockAuthorization
    class AuthorizeEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        request.params[:client_id]
      end

      def tags
        [EHR_AUTHORIZE_TAG]
      end

      def make_response
        if request.params[:redirect_uri].present?
          redirect_uri = "#{request.params[:redirect_uri]}?" \
                         "code=#{SecureRandom.hex}&" \
                         "state=#{request.params[:state]}"
          response.status = 302
          response.headers['Location'] = redirect_uri
        else
          response.status = 400
          response.format = :json
          response.body = FHIR::OperationOutcome.new(
            issue: FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'required',
                                                     details: FHIR::CodeableConcept.new(
                                                       text: 'No redirect_uri provided'
                                                     ))
          ).to_json
        end
      end
    end
  end
end
