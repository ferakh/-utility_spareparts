const cds = require('@sap/cds')

const { Parts, SpareRequests, IntegrationLogs } = cds.entities('utility.spareparts')

module.exports = cds.service.impl(function () {
  this.on('requestSparePart', async (req) => {
    const {
      part_ID,
      quantity,
      technicianName,
      technicianEmail,
      priority,
      requestedFor,
      notes
    } = req.data

    if (!part_ID) return req.reject(400, 'part_ID is required')
    if (!quantity || quantity < 1) return req.reject(400, 'quantity must be greater than 0')
    if (!technicianName) return req.reject(400, 'technicianName is required')

    const part = await SELECT.one.from(Parts).where({ ID: part_ID })
    if (!part) return req.reject(404, `Part ${part_ID} was not found`)
    if (part.active === false) return req.reject(400, `Part ${part_ID} is inactive`)

    const status = part.stockQuantity >= quantity
      ? 'PURCHASE_ORDER_CREATED'
      : 'STOCK_NOT_AVAILABLE'

    const ID = cds.utils.uuid()
    const requestNumber = `SR-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${ID.slice(0, 8).toUpperCase()}`

    await INSERT.into(SpareRequests).entries({
      ID,
      requestNumber,
      technicianName,
      technicianEmail,
      part_ID,
      quantity,
      status,
      priority: priority || 'NORMAL',
      requestedFor,
      notes
    })

    await INSERT.into(IntegrationLogs).entries({
      request_ID: ID,
      integrationStep: 'REQUEST_CREATED',
      direction: 'OUTBOUND',
      status,
      message: `Spare-part request ${requestNumber} created`
    })

    return SELECT.one.from(SpareRequests).where({ ID })
  })
})
