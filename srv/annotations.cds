using FieldMaintenanceService as field from './field-maintenance-service';
using AdminService as admin from './admin-service';
using IntegrationService as integration from './integration-service';

annotate field.Parts with @(
  UI.HeaderInfo: {
    TypeName: 'Part',
    TypeNamePlural: 'Parts',
    Title: { Value: name },
    Description: { Value: partNumber }
  },
  UI.SelectionFields: [partNumber, name, category, active],
  UI.LineItem: [
    { Value: partNumber, Label: 'Part Number' },
    { Value: name, Label: 'Name' },
    { Value: category, Label: 'Category' },
    { Value: stockQuantity, Label: 'Stock' },
    { Value: reorderLevel, Label: 'Reorder Level' },
    { Value: supplierName, Label: 'Supplier' },
    { Value: active, Label: 'Active' }
  ],
  UI.Facets: [
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Part Details',
      Target: '@UI.FieldGroup#Details'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Stock',
      Target: '@UI.FieldGroup#Stock'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Supplier',
      Target: '@UI.FieldGroup#Supplier'
    }
  ],
  UI.FieldGroup #Details: {
    Data: [
      { Value: partNumber, Label: 'Part Number' },
      { Value: name, Label: 'Name' },
      { Value: description, Label: 'Description' },
      { Value: category, Label: 'Category' },
      { Value: unitOfMeasure, Label: 'Unit' },
      { Value: active, Label: 'Active' }
    ]
  },
  UI.FieldGroup #Stock: {
    Data: [
      { Value: stockQuantity, Label: 'Stock Quantity' },
      { Value: reorderLevel, Label: 'Reorder Level' }
    ]
  },
  UI.FieldGroup #Supplier: {
    Data: [
      { Value: supplierName, Label: 'Supplier Name' },
      { Value: supplierPartNo, Label: 'Supplier Part Number' }
    ]
  }
);

annotate field.SpareRequests with @(
  UI.HeaderInfo: {
    TypeName: 'Spare Request',
    TypeNamePlural: 'Spare Requests',
    Title: { Value: requestNumber },
    Description: { Value: status }
  },
  UI.SelectionFields: [requestNumber, status, priority, technicianName],
  UI.LineItem: [
    { Value: requestNumber, Label: 'Request Number' },
    { Value: status, Label: 'Status' },
    { Value: priority, Label: 'Priority' },
    { Value: technicianName, Label: 'Technician' },
    { Value: quantity, Label: 'Quantity' },
    { Value: requestedFor, Label: 'Requested For' },
    { Value: externalReference, Label: 'External Reference' }
  ],
  UI.Facets: [
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Request Details',
      Target: '@UI.FieldGroup#Details'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Integration Status',
      Target: '@UI.FieldGroup#Integration'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Photos',
      Target: 'photos/@UI.LineItem'
    }
  ],
  UI.FieldGroup #Details: {
    Data: [
      { Value: requestNumber, Label: 'Request Number' },
      { Value: part, Label: 'Part' },
      { Value: quantity, Label: 'Quantity' },
      { Value: technicianName, Label: 'Technician' },
      { Value: technicianEmail, Label: 'Technician Email' },
      { Value: priority, Label: 'Priority' },
      { Value: requestedFor, Label: 'Requested For' },
      { Value: notes, Label: 'Notes' }
    ]
  },
  UI.FieldGroup #Integration: {
    Data: [
      { Value: status, Label: 'Status' },
      { Value: externalReference, Label: 'External Reference' },
      { Value: lastError, Label: 'Last Error' }
    ]
  }
);

annotate field.RequestPhotos with @(
  UI.HeaderInfo: {
    TypeName: 'Request Photo',
    TypeNamePlural: 'Request Photos',
    Title: { Value: fileName },
    Description: { Value: mimeType }
  },
  UI.LineItem: [
    { Value: fileName, Label: 'File Name' },
    {
      $Type: 'UI.DataFieldWithUrl',
      Label: 'Download',
      Value: 'Open Image',
      Url: contentUrl
    },
    { Value: mimeType, Label: 'MIME Type' },
    { Value: description, Label: 'Description' },
    { Value: createdAt, Label: 'Uploaded At' }
  ],
  UI.FieldGroup #Details: {
    Data: [
      { Value: fileName, Label: 'File Name' },
      { Value: mimeType, Label: 'MIME Type' },
      { Value: description, Label: 'Description' },
      { Value: createdAt, Label: 'Uploaded At' }
    ]
  }
);

annotate admin.SpareRequests with @(
  UI.HeaderInfo: {
    TypeName: 'Spare Request',
    TypeNamePlural: 'Spare Requests',
    Title: { Value: requestNumber },
    Description: { Value: status }
  },
  UI.SelectionFields: [requestNumber, status, priority, technicianName],
  UI.LineItem: [
    { Value: requestNumber, Label: 'Request Number' },
    { Value: status, Label: 'Status' },
    { Value: priority, Label: 'Priority' },
    { Value: technicianName, Label: 'Technician' },
    { Value: quantity, Label: 'Quantity' },
    { Value: externalReference, Label: 'External Reference' },
    { Value: lastError, Label: 'Last Error' }
  ]
);

annotate admin.Parts with @(
  UI.HeaderInfo: {
    TypeName: 'Part',
    TypeNamePlural: 'Parts',
    Title: { Value: name },
    Description: { Value: partNumber }
  },
  UI.SelectionFields: [partNumber, name, category, active],
  UI.LineItem: [
    { Value: partNumber, Label: 'Part Number' },
    { Value: name, Label: 'Name' },
    { Value: category, Label: 'Category' },
    { Value: stockQuantity, Label: 'Stock' },
    { Value: reorderLevel, Label: 'Reorder Level' },
    { Value: supplierName, Label: 'Supplier' },
    { Value: active, Label: 'Active' }
  ]
);

annotate admin.RequestPhotos with @(
  UI.HeaderInfo: {
    TypeName: 'Request Photo',
    TypeNamePlural: 'Request Photos',
    Title: { Value: fileName },
    Description: { Value: mimeType }
  },
  UI.LineItem: [
    { Value: createdAt, Label: 'Uploaded At' },
    { Value: fileName, Label: 'File Name' },
    {
      $Type: 'UI.DataFieldWithUrl',
      Label: 'Download',
      Value: 'Open Image',
      Url: contentUrl
    },
    { Value: mimeType, Label: 'MIME Type' },
    { Value: description, Label: 'Description' }
  ]
);

annotate admin.IntegrationLogs with @(
  UI.HeaderInfo: {
    TypeName: 'Integration Log',
    TypeNamePlural: 'Integration Logs',
    Title: { Value: integrationStep },
    Description: { Value: status }
  },
  UI.SelectionFields: [integrationStep, direction, status],
  UI.LineItem: [
    { Value: createdAt, Label: 'Created At' },
    { Value: integrationStep, Label: 'Step' },
    { Value: direction, Label: 'Direction' },
    { Value: status, Label: 'Status' },
    { Value: message, Label: 'Message' },
    { Value: retryCount, Label: 'Retry Count' }
  ]
);

annotate admin.SupplierResponses with @(
  UI.HeaderInfo: {
    TypeName: 'Supplier Response',
    TypeNamePlural: 'Supplier Responses',
    Title: { Value: supplierName },
    Description: { Value: acknowledgementStatus }
  },
  UI.SelectionFields: [supplierName, acknowledgementStatus],
  UI.LineItem: [
    { Value: receivedAt, Label: 'Received At' },
    { Value: supplierName, Label: 'Supplier' },
    { Value: acknowledgementStatus, Label: 'Status' },
    { Value: externalAcknowledgementId, Label: 'Acknowledgement ID' },
    { Value: message, Label: 'Message' }
  ]
);

annotate integration.IntegrationLogs with @(
  UI.LineItem: [
    { Value: createdAt, Label: 'Created At' },
    { Value: integrationStep, Label: 'Step' },
    { Value: direction, Label: 'Direction' },
    { Value: status, Label: 'Status' },
    { Value: message, Label: 'Message' },
    { Value: retryCount, Label: 'Retry Count' }
  ]
);

annotate integration.SupplierResponses with @(
  UI.LineItem: [
    { Value: receivedAt, Label: 'Received At' },
    { Value: supplierName, Label: 'Supplier' },
    { Value: acknowledgementStatus, Label: 'Status' },
    { Value: externalAcknowledgementId, Label: 'Acknowledgement ID' },
    { Value: message, Label: 'Message' }
  ]
);
