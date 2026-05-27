# Utility Spare Parts Deployment

This project is prepared for SAP BTP Cloud Foundry deployment as an MTA.

## What Gets Deployed

- CAP Node.js service module: `utility-spareparts-srv`
- App Router module: `utility-spareparts-router`
- SAP HANA HDI container: `utility-spareparts-db`
- HDI deployer module: `utility-spareparts-db-deployer`
- XSUAA instance: `utility-spareparts-auth`
- HTML5 Application Repository host: `utility-spareparts-html5-service`
- Destination service: `utility-spareparts-destination-service`
- Fiori HTML5 app content: `utility-spareparts-field-maintenance-ui`

## Build And Deploy From BAS

Log in to Cloud Foundry from a BAS terminal:

```bash
cf login
cf target
```

Install project dependencies:

```bash
npm install
```

Build the MTA archive:

```bash
npm run build
```

Deploy the generated archive:

```bash
npm run deploy
```

Check the deployed app route:

```bash
cf apps
```

The CAP service root will be available at the service route:

```text
https://<utility-spareparts-srv-route>/odata/v4/
```

The browser login entry point is the App Router route:

```text
https://<utility-spareparts-router-route>/odata/v4/field-maintenance/
```

Use the App Router route for human browser testing. It performs the XSUAA login flow and forwards your user token to the CAP service.

## SAP Build Work Zone

The MTA deploys the Fiori UI as HTML5 application content for SAP Build Work Zone.

After deployment:

1. Open SAP Build Work Zone, standard edition.
2. Open Channel Manager or Content Manager.
3. Refresh the HTML5 Apps content provider.
4. Add the `utility.spareparts.fieldmaintenanceui` app to a catalog/group/site.
5. Publish the site.

The existing Cloud Foundry App Router URL remains available as a fallback:

```text
https://<utility-spareparts-router-route>/field-maintenance-ui/index.html
```

## Integration Suite Target Endpoints

Use the deployed service route, not the BAS preview URL. Integration Suite should call the direct CAP service route with OAuth client credentials.

```text
POST https://<utility-spareparts-srv-route>/odata/v4/integration/updateRequestStatus
POST https://<utility-spareparts-srv-route>/odata/v4/integration/receiveSupplierAcknowledgement
```

Example status update body:

```json
{
  "request_ID": "PASTE_REQUEST_ID",
  "status": "PURCHASE_ORDER_CREATED",
  "message": "Purchase order created by Integration Suite",
  "externalReference": "PO-900001"
}
```

Example supplier acknowledgement body:

```json
{
  "request_ID": "PASTE_REQUEST_ID",
  "supplierName": "Apex Industrial Supply",
  "acknowledgementStatus": "SUPPLIER_CONFIRMED",
  "message": "Supplier confirmed fulfilment",
  "externalAcknowledgementId": "ACK-10001"
}
```

## Authentication Notes

The deployment creates an XSUAA instance.

- `FieldMaintenanceService` requires an authenticated user.
- `AdminService` requires the `Admin` role.
- `IntegrationService` requires the `IntegrationUser` scope.

For Integration Suite, create a service key for `utility-spareparts-auth`, then use its OAuth client credentials in an Integration Suite HTTP receiver adapter.

```bash
cf create-service-key utility-spareparts-auth integration-suite-key
cf service-key utility-spareparts-auth integration-suite-key
```

Use the service key values:

- `url` as the token service base URL
- `clientid` as the OAuth client ID
- `clientsecret` as the OAuth client secret

Request token URL:

```text
<url>/oauth/token
```

Token request settings:

- Grant type: `client_credentials`
- Client ID: service key `clientid`
- Client Secret: service key `clientsecret`

The XSUAA descriptor grants the technical client the `IntegrationUser` authority, so Integration Suite can call the integration endpoints.

For human admin testing, create a role collection in BTP cockpit that includes the generated `Admin` role, then assign it to your user.

After assigning the role collection, use the App Router URL in your browser:

```text
https://<utility-spareparts-router-route>/odata/v4/admin/
```
