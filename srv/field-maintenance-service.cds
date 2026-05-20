using { utility.spareparts as db } from '../db/schema';

@requires: 'authenticated-user'
service FieldMaintenanceService {
  entity Parts as projection on db.Parts;
  entity SpareRequests as projection on db.SpareRequests;

  action requestSparePart(
    part_ID          : UUID,
    quantity         : Integer,
    technicianName   : String,
    technicianEmail  : String,
    priority         : String,
    requestedFor     : Date,
    notes            : String
  ) returns SpareRequests;
}
