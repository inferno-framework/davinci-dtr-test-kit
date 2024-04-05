# Da Vinci Documentation Templates and Rules (DTR) Test Kit

This is an [Inferno](https://github.com/inferno-community/inferno-core) 
test kit for the [Da Vinci Documentation Templates and Rules (DTR) FHIR
Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/).

It contains test kits to test the four actors defined by the DTR specification:
- Payer Server: responsible for serving up questionnaires.
- Full DTR EMR: responsible for retriving questionnaires from a payer server, 
  filling them out based on local data and user input, and storing them
  locally.
- Light DTR EMR: responsible for serving data that a DTR Smart App can use to
  populate questionnaires.
- DTR Smart App: responsible for retrieving questionnaires from a payer server,
  completing them using data retrieved from a Light DTR EMR and user input, and
  storing the results back to the Light DTR EMR.

## Exercising the test kit

To exercise the test kit for the purposes of demoing or debugging, one option is to use the HL7 Da Vinci Documentation
Requirements Lookup Service (DRLS) reference implementation. Instructions to set up the reference implementation can be
found [here](https://github.com/HL7-DaVinci/CRD/blob/master/SetupGuideForMacOS.md). This setup includes downloading five
different git repositories. The repository for DTR has been forked to make it usable with this test kit here:
https://gitlab.mitre.org/inferno/dtr. That fork should be used instead of the upstream version.

If you get an SSL error when starting DTR or crd-request-generator, start them with the following command:
```sh
NODE_OPTIONS=--openssl-legacy-provider npm start
```

**IMPORTANT:** the DTR reference implementation does not perform token exchange before making requests to the payer
server. Therefore, the DTR fork has a bearer token hard-coded into requests. When running the test kit This specific
value must be used as the payer server access token:
```
d06d1d119a191d974d55fde1cdc55ee0
```


## License
Copyright 2022 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
