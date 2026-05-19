const cds = require('@sap/cds')

const { SpareRequests, IntegrationLogs } = cds.entities('utility.spareparts')

module.exports = cds.service.impl(function () {
  this.on('retryFailedRequest', async (req) => {
    const { request_ID, message } = req.data

    if (!request_ID) return req.reject(400, 'request_ID is required')

    const spareRequest = await SELECT.one.from(SpareRequests).where({ ID: request_ID })
    if (!spareRequest) return req.reject(404, `Spare request ${request_ID} was not found`)

    const latestLog = await SELECT.one.from(IntegrationLogs)
      .where({ request_ID })
      .orderBy('createdAt desc')

    await UPDATE(SpareRequests).set({
      status: 'RETRY_REQUESTED',
      lastError: null
    }).where({ ID: request_ID })

    await INSERT.into(IntegrationLogs).entries({
      request_ID,
      integrationStep: 'RETRY_REQUESTED',
      direction: 'OUTBOUND',
      status: 'RETRY_REQUESTED',
      message: message || 'Retry requested by admin',
      retryCount: latestLog ? (latestLog.retryCount || 0) + 1 : 1
    })

    return SELECT.one.from(SpareRequests).where({ ID: request_ID })
  })

  this.on('markAsManualReview', async (req) => {
    const { request_ID, message } = req.data

    if (!request_ID) return req.reject(400, 'request_ID is required')

    const spareRequest = await SELECT.one.from(SpareRequests).where({ ID: request_ID })
    if (!spareRequest) return req.reject(404, `Spare request ${request_ID} was not found`)

    await UPDATE(SpareRequests).set({
      status: 'MANUAL_REVIEW_REQUIRED',
      lastError: message || 'Manual review required'
    }).where({ ID: request_ID })

    await INSERT.into(IntegrationLogs).entries({
      request_ID,
      integrationStep: 'MANUAL_REVIEW',
      direction: 'INTERNAL',
      status: 'MANUAL_REVIEW_REQUIRED',
      message: message || 'Manual review required'
    })

    return SELECT.one.from(SpareRequests).where({ ID: request_ID })
  })
})
