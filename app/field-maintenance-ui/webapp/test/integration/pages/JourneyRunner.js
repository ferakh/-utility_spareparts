sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"utility/spareparts/fieldmaintenanceui/test/integration/pages/SpareRequestsList",
	"utility/spareparts/fieldmaintenanceui/test/integration/pages/SpareRequestsObjectPage"
], function (JourneyRunner, SpareRequestsList, SpareRequestsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('utility/spareparts/fieldmaintenanceui') + '/test/flp.html#app-preview',
        pages: {
			onTheSpareRequestsList: SpareRequestsList,
			onTheSpareRequestsObjectPage: SpareRequestsObjectPage
        },
        async: true
    });

    return runner;
});

