namespace utility.spareparts;

using { cuid, managed } from '@sap/cds/common';

entity Parts : cuid, managed {
  partNumber      : String(40) not null;
  name            : String(100) not null;
  description     : String(255);
  category        : String(60);
  unitOfMeasure   : String(10) default 'EA';
  stockQuantity   : Integer default 0;
  reorderLevel    : Integer default 0;
  supplierName    : String(100);
  supplierPartNo  : String(60);
  active          : Boolean default true;
}

entity SpareRequests : cuid, managed {
  requestNumber     : String(40);
  technicianName    : String(100) not null;
  technicianEmail   : String(120);
  part              : Association to Parts;
  quantity          : Integer not null;
  status            : String(40) default 'STOCK_NOT_AVAILABLE';
  priority          : String(20) default 'NORMAL';
  requestedFor      : Date;
  notes             : String(500);
  externalReference : String(100);
  lastError         : String(500);
  supplierResponses : Association to many SupplierResponses on supplierResponses.request = $self;
  integrationLogs   : Association to many IntegrationLogs on integrationLogs.request = $self;
  photos            : Association to many RequestPhotos on photos.request = $self;
}

entity RequestPhotos : cuid, managed {
  request       : Association to SpareRequests;
  fileName      : String(255) not null;
  mimeType      : String(100) not null;
  @Core.MediaType: mimeType
  content       : LargeBinary;
  contentBase64 : LargeString not null;
  description   : String(500);
}

entity SupplierResponses : cuid, managed {
  request                   : Association to SpareRequests;
  supplierName              : String(100);
  acknowledgementStatus     : String(40);
  externalAcknowledgementId : String(100);
  message                   : String(500);
  receivedAt                : Timestamp;
}

entity IntegrationLogs : cuid, managed {
  request         : Association to SpareRequests;
  integrationStep : String(60);
  direction       : String(20);
  status          : String(40);
  message         : String(500);
  payload         : LargeString;
  retryCount      : Integer default 0;
}
