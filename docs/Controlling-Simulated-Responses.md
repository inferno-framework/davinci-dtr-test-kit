# Controlling Responses from Inferno's Simulated DTR Payer Server

During the DTR client tests, client systems are asked to demonstrate
that they can handle and complete Questionnaires meeting certain requirements.
Some of the scenarios in the client tests require testers to complete
Inferno-built Questionnaires to prove conformance to certain requirements.
However, many of them allow testers to provide their own Questionnaires and
in generaly, Inferno does not have Questionnaires that demonstrate all of
the capabilities of the DTR specification, so in practice testers will
need to provide some Questionnaires for Inferno to provide back as a part
of its DTR payer server simulation. This page describes how testers specify
and control Inferno's resposnes to requests for Questionnaires.

## Response Templates

Inferno's DTR Payer server simulation includes endpoints for the following three
operations:
- `Questionnaire/$questionnaire-package`
- `Questionnaire/$next-question`
- `ValueSet/$expand`

Certain tests provide inputs for response templates that drive Inferno's responses
when it has identified an incoming request as associated with the waiting session.
In all cases, these templates can include instructions that dynamically change
the response based on the request content through [inclusion criteria](#inclusion-criteria)
and [tokens](#dynamic-tokens). The following sections describe the format
the response templates for each operation and where dynamic instructions can
appear in them.

### `Questionnaire/$questionnaire-package`

A template for `$questionnaire-package` responses takes the form of a FHIR
Parameters resource in json format. [Inclusion criteria](#inclusion-criteria)
extensions can appear within the `parameter` entries. The `parameter` entries
returned for a particular request will be those without inclusion criteria
and those with inclusion criteria that are met by the Parameters request body.
Thus, the template could define multiple 'packagebundle'
and/or 'outcome' `parameter` entries, but return them only for certain requests,
e.g., certain coverages, orders, or Questionnaires. Inclusion criteria extensions
will be removed and [tokens](#dynamic-tokens) found within selected `parameter`
entries will be replaced before responding.

Alternatively, the template can be a FHIR OperationOutcome if an error response
is appropriate. [Tokens](#dynamic-tokens) are not instantiated within
the OperationOutcome.

### `Questionnaire/$next-question`

A template for `$next-question` responses takes the form of a json array
containing one or more FHIR Questionnaire resources in json format.
If only a single Questionnaire is provided, it does not have to be wrapped in
a json list. Each Questionnaire contains `item` entries, possibly nested,
and these `item` entries can contain selection criteria.

When a `$next-question` request is received with a QustionnaireResponse as the body,
Inferno first selects the right Questionnaire to use as a template by identifying
the the Questionnaire in the template list that matches the contained Questionnaire
in the request, based on `url` and `version` if present in the request.
Inferno then uses the template to select which, if any, `item` entries from the template
to add to the contained Questionnaire. Inferno will add an item if
1. It is not already present within the contained Questionnaire in the request.
2. Its parent was already present or has been added.
3. It has no inclusion criteria or the inclusion criteria are met when evaluated
   against the QuestionnaireResponse from the request body.

Note that `item` entries are never removed from the contained Questionnaire.
[Inclusion criteria](#inclusion-criteria) extensions will be removed from items
before adding them and [tokens](#dynamic-tokens) found within added `item`
entries will be replaced.

Additionally, if no new questions were added and all required questions have answers,
the Inferno will mark the QuestionnaireRepsonse as complete by changing the
`status` element to 'completed'.

### `ValueSet/$expand`

TODO - not implemented yet

## Specifying Dynamic Content in Response Templates

### Inclusion Criteria

Inclusion criteria extension options include:
- `urn:inferno:dtr:inclusion-criteria`: element `valueExpression.expression` contains
  a FHIRPath expression executed against the QuestionnaireResponse from the request.
  To determine inclusion, the FHIRPath result is interpreted as a boolean where
  - empty collections, collections with multiple entries, and collections with a single `false`
    value are interepreted as `false`.
  - all other collections interpreted as `true`.
- `urn:inferno:dtr:request-range`: element `valueString` contains a single or comma-separated
  list of 1-indexed request numbers or ranges indicaing the requests that the item can first
  be included the response. For example, "1,3-5" would mean that the item would be added on
  request 1, 3, 4, or 5 if its parent were already present or also added.

If multiple criteria are included, all must be met for the item to be included. Recall that if
the item is nested under another item, its parent must already present or added for the child
to be evaluated for inclusion.

### Dynamic Tokens

Tokens of the form `{{<fhirpath>}}` within response templates are replaced with the results
of the `<fhirpath>>` executed against the request body. The results of the FHIRpath
must be one or more strings and results with more than one string are  converted into a
single string separated by commas. Results that are objects and arrays will be silently discarded.