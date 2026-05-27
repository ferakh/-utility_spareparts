const cds = require('@sap/cds')

const { SpareRequests, SupplierResponses, IntegrationLogs } = cds.entities('utility.spareparts')

const SUPPLIER_STATUS_MAP = {
  SUPPLIER_CONFIRMED: 'SUPPLIER_CONFIRMED',
  CONFIRMED: 'SUPPLIER_CONFIRMED',
  SUPPLIER_REJECTED: 'SUPPLIER_REJECTED',
  REJECTED: 'SUPPLIER_REJECTED'
}

module.exports = cds.service.impl(function () {
  this.on('recordIntegrationLog', async (req) => {
    const {
      request_ID,
      integrationStep,
      direction,
      status,
      message,
      payload
    } = req.data

    if (!integrationStep) return req.reject(400, 'integrationStep is required')
    if (!direction) return req.reject(400, 'direction is required')
    if (!status) return req.reject(400, 'status is required')

    const ID = cds.utils.uuid()
    await INSERT.into(IntegrationLogs).entries({
      ID,
      request_ID,
      integrationStep,
      direction,
      status,
      message,
      payload
    })

    return SELECT.one.from(IntegrationLogs).where({ ID })
  })

  this.on('updateRequestStatus', async (req) => {
    const { request_ID, status, message, externalReference } = req.data

    if (!request_ID) return req.reject(400, 'request_ID is required')
    if (!status) return req.reject(400, 'status is required')

    const spareRequest = await SELECT.one.from(SpareRequests).where({ ID: request_ID })
    if (!spareRequest) return req.reject(404, `Spare request ${request_ID} was not found`)

    await UPDATE(SpareRequests).set({
      status,
      externalReference,
      lastError: status === 'MANUAL_REVIEW_REQUIRED' ? message : null
    }).where({ ID: request_ID })

    await INSERT.into(IntegrationLogs).entries({
      request_ID,
      integrationStep: 'STATUS_UPDATE',
      direction: 'INBOUND',
      status,
      message,
      payload: JSON.stringify(req.data)
    })

    return { request_ID, status, externalReference, message }
  })

  this.on('receiveSupplierAcknowledgement', async (req) => {
    const {
      request_ID,
      supplierName,
      acknowledgementStatus,
      message,
      externalAcknowledgementId
    } = req.data

    if (!request_ID) return req.reject(400, 'request_ID is required')
    if (!acknowledgementStatus) return req.reject(400, 'acknowledgementStatus is required')

    const spareRequest = await SELECT.one.from(SpareRequests).where({ ID: request_ID })
    if (!spareRequest) return req.reject(404, `Spare request ${request_ID} was not found`)

    const status = SUPPLIER_STATUS_MAP[acknowledgementStatus] || acknowledgementStatus
    const ID = cds.utils.uuid()

    await INSERT.into(SupplierResponses).entries({
      ID,
      request_ID,
      supplierName,
      acknowledgementStatus: status,
      externalAcknowledgementId,
      message,
      receivedAt: new Date()
    })

    await UPDATE(SpareRequests).set({
      status,
      lastError: status === 'SUPPLIER_REJECTED' ? message : null
    }).where({ ID: request_ID })

    await INSERT.into(IntegrationLogs).entries({
      request_ID,
      integrationStep: 'SUPPLIER_ACKNOWLEDGEMENT',
      direction: 'INBOUND',
      status,
      message,
      payload: JSON.stringify(req.data)
    })

    return SELECT.one.from(SupplierResponses).where({ ID })
  })
})
