using { utility.spareparts as db } from '../db/schema';

@requires: 'authenticated-user'
service FieldMaintenanceService {
  entity Parts as projection on db.Parts;
  entity SpareRequests as projection on db.SpareRequests;
  entity RequestPhotos as projection on db.RequestPhotos;

  action requestSparePart(
    part_ID          : UUID,
    quantity         : Integer,
    technicianName   : String,
    technicianEmail  : String,
    priority         : String,
    requestedFor     : Date,
    notes            : String
  ) returns SpareRequests;

  action addRequestPhoto(
    request_ID     : UUID,
    fileName       : String,
    mimeType       : String,
    contentBase64  : LargeString,
    description    : String
  ) returns RequestPhotos;
}
