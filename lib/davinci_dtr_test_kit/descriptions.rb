# frozen_string_literal: true

module DaVinciDTRTestKit
  INPUT_CLIENT_ID_LOCKED =
    'If this session has been configured for standards-based authentication, this input ' \
    'contains the client\'s registered Client Id for use in obtaining access tokens. ' \
    'Run the **1** Client Registration group to configure standards-based auth.'
  INPUT_SESSION_URL_PATH_LOCKED =
    'If this session has been configured for dedicated endpoints authentication, this input ' \
    'contains the additional path used to create session-specific endpoints. If neither this ' \
    'nor the `Client Id` input are populated, the dedicated endpoints approach will be used ' \
    'with the session id as the additional path. Run the **1** Client Registration group ' \
    'to provide a tester-chosen value for this input.'
  INPUT_JWK_SET_LOCKED =
    'If this session has been configured for SMART Backend Services authentication, this input ' \
    'contains either a publicly accessible url pointing to the JSON Web Key Set (JWKS), or the ' \
    'raw JWKS. Run the **1** Client Registration group to configure this session for SMART Backend ' \
    'Services authentication.'
end
