# Controlling Requests from Inferno's Simulated DTR Client

During the DTR payer tests, payer systems are asked to demonstrate
that they can respond to requests for Questionnaires. Inferno does not know
and seeks to avoid making assumptions about the configuration and business logic
that determines whether a request will return a Questionnaire or not. Therefore,
Inferno requires testers to provide requests for Inferno to use when
simulating a DTR client during these tests. This page describes how testers
specify and control the requests that Inferno will make while testing.

## $questionnaire-package Requests

Testers will provide the verbatim $questionnaire-package request body for Inferno
to use when making the requests. The specific input will specify whether multiple
requests can be provided or not.

## $next-question Requests

When completing adaptive Questionnaires, DTR clients iteratively make requests
in the form of a QuestionnaireResponse with a contained Questionnaire and receiving
back the same with either additional questions added to the the contained Questionnaire
or an indication that the QuestionnaireResponse is now complete. In this way,
both the responses and the subsequent request are designed to be reactions to the preceding
response or request.

Rather that specify a sequence of requests for Inferno to make that may or may not match
the preceding response, Inferno asks testers to specify for each adaptive Questionnaire that
the simulated DTR client may receive from the payer the end state in the form of a
QuestionnaireResponse template with questions answered. 

For each adaptive Questionnaire returned from a $questionnaire-package request, Inferno will
identify the template to use using the Questionnaire's canonical URL. It will
make an initial $next-question request using the with QuestionnaireResponse
from the $questionnaire-package response. Inferno will then construct
subsequent $next-question request bodies by adding responses to the QuestionnaireResponse from
the identified template. Inferno will make $next-question requests until either
1. A non-successful response is returned by the payer, or
2. The payer indicates that the QuestionnaireResponse is completed, or
3. No new questions were added by the payer, or
4. The template had no answers to add based on the new questions added.

### Current Limitations

At this time, only a single template may be provided for each Questionnaire canonical url
(first one in the list will be used), meaning that Inferno can only fill out each
Questionnaire one way. In the future, additional selection criteria may be added that allows
the template to be chosen based on the contents of the $questionnaire-package request.