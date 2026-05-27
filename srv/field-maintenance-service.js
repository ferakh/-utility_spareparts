const cds = require('@sap/cds')

const { Parts, SpareRequests, RequestPhotos, IntegrationLogs } = cds.entities('utility.spareparts')

module.exports = cds.service.impl(function () {
  this.on('addRequestPhoto', async (req) => {
    const {
      request_ID,
      fileName,
      mimeType,
      contentBase64,
      description
    } = req.data

    if (!request_ID) return req.reject(400, 'request_ID is required')
    if (!fileName) return req.reject(400, 'fileName is required')
    if (!mimeType) return req.reject(400, 'mimeType is required')
    if (!mimeType.startsWith('image/')) return req.reject(400, 'mimeType must be an image type')
    if (!contentBase64) return req.reject(400, 'contentBase64 is required')

    let normalizedContent = contentBase64
    const dataUrlMatch = contentBase64.match(/^data:([^;]+);base64,(.*)$/)
    if (dataUrlMatch) {
      if (dataUrlMatch[1] !== mimeType) return req.reject(400, 'mimeType does not match the data URL')
      normalizedContent = dataUrlMatch[2]
    }

    const photoBytes = Buffer.from(normalizedContent, 'base64')
    if (!photoBytes.length) return req.reject(400, 'contentBase64 is empty')
    if (photoBytes.length > 5 * 1024 * 1024) return req.reject(400, 'photo must be 5 MB or smaller')

    const spareRequest = await SELECT.one.from(SpareRequests).where({ ID: request_ID })
    if (!spareRequest) return req.reject(404, `Spare request ${request_ID} was not found`)

    const ID = cds.utils.uuid()
    await INSERT.into(RequestPhotos).entries({
      ID,
      request_ID,
      fileName,
      mimeType,
      contentBase64: normalizedContent,
      description
    })

    await INSERT.into(IntegrationLogs).entries({
      request_ID,
      integrationStep: 'PHOTO_ATTACHED',
      direction: 'INBOUND',
      status: 'PHOTO_RECEIVED',
      message: `Photo ${fileName} attached to spare-part request ${spareRequest.requestNumber || request_ID}`,
      payload: JSON.stringify({ fileName, mimeType, description, size: photoBytes.length })
    })

    return SELECT.one.from(RequestPhotos).where({ ID })
  })

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
