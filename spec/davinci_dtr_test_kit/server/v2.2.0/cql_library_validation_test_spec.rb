RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::CQLLibraryValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:library_url) { 'http://example.com/fhir/library' }
  let(:library_version) { '0.1' }
  let(:library_canonical) { "#{library_url}|#{library_version}" }
  let(:dependent_library_url) { 'http://example.com/fhir/dependent-library' }
  let(:dependent_library_version) { '0.2' }
  let(:dependent_library_canonical) do
    "#{dependent_library_url}|#{dependent_library_version}"
  end
  let(:nested_library_url) { 'http://example.com/fhir/nested-library' }
  let(:nested_library_version) { '0.3' }
  let(:nested_library_canonical) do
    "#{nested_library_url}|#{nested_library_version}"
  end
  let(:q_with_lib_ref) do
    FHIR::Questionnaire.new(
      extension: [
        {
          url: 'http://hl7.org/fhir/StructureDefinition/cqf-library',
          valueCanonical: library_canonical
        }
      ]
    )
  end

  def build_bundle(questionnaire, libraries = [])
    bundle_hash = {
      entry: [
        {
          resource: questionnaire
        }
      ]
    }

    libraries.each do |library|
      bundle_hash[:entry] << { resource: library }
    end

    FHIR::Bundle.new(bundle_hash)
  end

  def response_params(bundle)
    FHIR::Parameters.new(
      parameter: [
        {
          name: 'packagebundle',
          resource: bundle
        }
      ]
    )
  end

  def valid_library(url:, version:, name:, dependencies: [])
    FHIR::Library.new(
      url:,
      name:,
      version:,
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        },
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ],
      relatedArtifact: dependencies.map do |canonical|
        {
          type: 'depends-on',
          resource: canonical
        }
      end
    )
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  it 'skips if no requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No successful $questionnaire-package')
  end

  it 'skips if no successful requests have been made' do
    request = repo_create(:request, status: 400, response_body: '{}')

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No successful $questionnaire-package')
  end

  it 'omits if no responses contain libraries' do
    bundle = build_bundle(FHIR::Questionnaire.new)
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('omit')
  end

  it 'fails if a library does not contain cql' do
    library = FHIR::Library.new(
      url: library_url,
      version: library_version,
      content: [
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ]
    )
    bundle = build_bundle(q_with_lib_ref, [library])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('does not include CQL')
  end

  it 'fails if a library does not contain elm' do
    library = FHIR::Library.new(
      url: library_url,
      version: library_version,
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        }
      ]
    )
    bundle = build_bundle(q_with_lib_ref, [library])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('does not include ELM')
  end

  it 'fails if multiple libraries have the same name' do
    library1 = FHIR::Library.new(
      url: library_url,
      name: 'abc',
      version: library_version,
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        },
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ]
    )
    library2 = library1.dup
    library2.url = "#{library1.url}x"

    bundle = build_bundle(q_with_lib_ref, [library1, library2])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('contains multiple libraries named')
  end

  it 'fails if a referenced library is not included' do
    library = FHIR::Library.new(
      url: library_url,
      name: 'abc',
      version: "#{library_version}.1",
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        },
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ]
    )

    bundle = build_bundle(q_with_lib_ref, [library])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('libraries are referenced but not included')
  end

  it 'fails if a non-versioned library reference is present' do
    q_with_lib_ref.extension.first.valueCanonical = library_url
    library = FHIR::Library.new(
      url: library_url,
      name: 'abc',
      version: library_version,
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        },
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ]
    )

    bundle = build_bundle(q_with_lib_ref, [library])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.first.message).to include('unversioned library references')
  end

  it 'fails if a nested Library dependency is not included' do
    library = valid_library(
      url: library_url,
      version: library_version,
      name: 'library',
      dependencies: [dependent_library_canonical]
    )
    dependent_library = valid_library(
      url: dependent_library_url,
      version: dependent_library_version,
      name: 'dependent-library',
      dependencies: [nested_library_canonical]
    )

    bundle = build_bundle(q_with_lib_ref, [library, dependent_library])
    stored_exchange = repo_create(
      :request,
      status: 200,
      response_body: response_params(bundle).to_json
    )

    allow_any_instance_of(described_class).to receive(:requests).and_return([stored_exchange])

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join("\n")).to include(nested_library_canonical)
  end

  it 'passes if all nested Library dependencies are included and valid' do
    library = valid_library(
      url: library_url,
      version: library_version,
      name: 'library',
      dependencies: [dependent_library_canonical]
    )
    dependent_library = valid_library(
      url: dependent_library_url,
      version: dependent_library_version,
      name: 'dependent-library',
      dependencies: [nested_library_canonical]
    )
    nested_library = valid_library(
      url: nested_library_url,
      version: nested_library_version,
      name: 'nested-library'
    )

    bundle = build_bundle(q_with_lib_ref, [library, dependent_library, nested_library])
    stored_exchange = repo_create(
      :request,
      status: 200,
      response_body: response_params(bundle).to_json
    )

    allow_any_instance_of(described_class).to receive(:requests).and_return([stored_exchange])

    result = run(described_class)

    expect(result.result).to eq('pass')
  end

  it 'passes if all referenced libraries are included and valid' do
    library = FHIR::Library.new(
      url: library_url,
      name: 'abc',
      version: library_version,
      content: [
        {
          contentType: 'text/cql',
          data: 'abc'
        },
        {
          contentType: 'application/elm+json',
          data: 'abc'
        }
      ]
    )

    bundle = build_bundle(q_with_lib_ref, [library])
    request = repo_create(:request, status: 200, response_body: response_params(bundle).to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('pass')
  end
end
