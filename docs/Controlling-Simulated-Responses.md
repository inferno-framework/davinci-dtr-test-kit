# Controlling Responses from Inferno's Simulated DTR Payer Server

During the DTR client tests, client systems are asked to demonstrate
that they can handle and complete Questionnaires meeting certain requirements.
Some of the scenarios in the client tests require testers to complete
Inferno-built Questionnaires to prove conformance to certain requirements.
However, many of them allow testers to provide their own Questionnaires.
Inferno does not have Questionnaires that demonstrate all of
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

Adaptive Questionnaires within a 'packagebundle' can be
[built from the `$next-question` template](#building-package-questionnaires-from-next-question-templates)
instead of being copied into this template.

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

### CQL Libraries and ValueSets

Some tests also provide inputs for a Bundle of CQL Library resources and a Bundle
of ValueSet resources. Rather than copying these resources into each template,
Inferno adds them to responses when the returned Questionnaires reference them.
A resource is referenced when its `url` (and `version`, if the reference includes
one, e.g., `http://example.org/Library/Example|1.0.0`) matches
- a `http://hl7.org/fhir/StructureDefinition/cqf-library` extension on a Questionnaire or item,
- an item's `answerValueSet`,
- an [`include-resource`](#including-libraries-and-valuesets) extension on a Questionnaire or item, or
- a `depends-on` `relatedArtifact` of a Library that is referenced, e.g., FHIRHelpers.

References that don't match a provided resource are ignored. Where the resources are
added depends on the operation:
- `$questionnaire-package`: referenced resources are added as entries to each
  'packagebundle' that doesn't already include them.
- `$next-question`: resources referenced by newly added items are added as
  `contained` resources of the returned QuestionnaireResponse, unless the client
  already has them from the request or from the `$questionnaire-package` response.

ValueSets from the provided Bundle are returned without their `expansion` unless
the ValueSet has an `include-value-set-expanded` extension with `valueBoolean`
set to `true`. ValueSets written directly into a `$questionnaire-package`
template keep any `expansion` they have, unless they have an `include-value-set-expanded`
extension that isn't `true`. The extension is removed before responding.
When an expansion is not included, DTR clients will need to use `ValueSet/$expand`
to get the codes included in the ValueSet.

## Specifying Dynamic Content in Response Templates

Inferno's control extensions all have urls of the form
`https://inferno.healthit.gov/test-kits/davinci-dtr/StructureDefinition/extension-<name>`,
and this page refers to them by `<name>`. Inferno removes them before responding.
The earlier urls `urn:inferno:dtr:inclusion-criteria` and `urn:inferno:dtr:request-range`
are still accepted for `inclusion-criteria` and `request-range`, but are deprecated.

### Inclusion Criteria

Inclusion criteria extension options include:
- `inclusion-criteria`: element `valueExpression.expression` contains
  a FHIRPath expression executed against the QuestionnaireResponse from the request.
  To determine inclusion, the FHIRPath result is interpreted as a boolean where
  - empty collections, collections with multiple entries, and collections with a single
    `false` value are interepreted as `false`.
  - all other collections interpreted as `true`.
- `request-range`: element `valueString` contains a single or comma-separated
  list of 1-indexed request numbers or ranges indicaing the requests that the item can first
  be included the response. For example, "1,3-5" would mean that the item would be added on
  request 1, 3, 4, or 5 if its parent were already present or also added.

If multiple criteria are included, all must be met for the item to be included. Recall that if
the item is nested under another item, its parent must already present or added for the child
to be evaluated for inclusion.

### Including Libraries and ValueSets

CQL expressions refer to Libraries by name rather than canonical url, so Inferno cannot
tell that an item needs a Library from its expressions. Add an `include-resource`
extension, whose `valueCanonical` contains the Library's canonical url, to the item (or Questionnaire)
to have Inferno include that Library from the provided Bundle when it returns the item.
See [CQL Libraries and ValueSets](#cql-libraries-and-valuesets) for details.

### Building Package Questionnaires from `$next-question` Templates

The Questionnaire returned by `$questionnaire-package` for an adaptive form is usually
the `$next-question` template's Questionnaire with only its first few items. To avoid
copying it, a Questionnaire in a 'packagebundle', or contained in a QuestionnaireResponse
in a 'packagebundle', can be a placeholder with a `use-next-question-questionnaire-template`
extension whose `valueCanonical` is the template Questionnaire's `url` (optionally
`url|version`). Inferno replaces the placeholder with a copy of the matching template
Questionnaire that keeps only
- the items with an `include-in-package` extension whose `valueBoolean` is `true`, and
- the items that contain them, so that groups are kept for their marked children
  (a group's unmarked children are not kept).

Elements set on the placeholder, such as `id`, take precedence over the template's, and
the placeholder's other extensions are added to the template's. For example:

```json
{
  "resourceType": "Questionnaire",
  "extension": [
    {
      "url": "https://inferno.healthit.gov/test-kits/davinci-dtr/StructureDefinition/extension-use-next-question-questionnaire-template",
      "valueCanonical": "https://example.org/Questionnaire/adaptive-example"
    }
  ]
}
```

Placeholders are expanded before [tokens](#dynamic-tokens) are replaced and before
[Libraries and ValueSets](#cql-libraries-and-valuesets) are added, so references in the
copied template are included. A placeholder that doesn't match any `$next-question` template
Questionnaire is an error, reported before the interaction starts when possible.

### Dynamic Tokens

Tokens of the form `{{<fhirpath>}}` within response templates are replaced with the results
of the `<fhirpath>` executed against the request body. The results of the FHIRpath
must be one or more strings and results with more than one string are converted into a
single string separated by commas. Results that are objects and arrays will be silently discarded.

The request body differs by operation: `$questionnaire-package` tokens are evaluated
against the request's Parameters resource, and `$next-question` tokens against the
request's QuestionnaireResponse. This matters for `$next-question` template items that are
[included in the package](#building-package-questionnaires-from-next-question-templates):
the copies of those items in the `$questionnaire-package` response have their tokens evaluated
against the `$questionnaire-package` Parameters, so a token written for the QuestionnaireResponse,
such as `{{item.where(linkId = 'name').answer.value}}`, will usually have no result and be
replaced with an empty string. In package-included items, use only tokens that make sense
for the `$questionnaire-package` request, such as ones that don't depend on the request content.