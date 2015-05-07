package org.openmrs.module.pihcore.deploy.bundle.liberia;

import org.openmrs.module.coreapps.CoreAppsConstants;
import org.openmrs.module.emrapi.EmrApiConstants;
import org.openmrs.module.metadatadeploy.bundle.Requires;
import org.openmrs.module.pihcore.deploy.bundle.PihMetadataBundle;
import org.openmrs.module.pihcore.deploy.bundle.core.PihCoreMetadataBundle;
import org.openmrs.module.pihcore.metadata.liberia.LiberiaLocations;
import org.openmrs.module.pihcore.metadata.liberia.LiberiaPatientIdentifierTypes;
import org.openmrs.util.OpenmrsConstants;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@Requires({ PihCoreMetadataBundle.class, LiberiaLocationsBundle.class, LiberiaPatientIdentifierTypeBundle.class, LiberiaAddressBundle.class } )
public class LiberiaMetadataBundle extends PihMetadataBundle {

    @Override
    public void install() throws Exception {

        log.info("Setting Global Properties");

        Map<String, String> properties = new LinkedHashMap<String, String>();

        // OpenMRS Core
        properties.put(OpenmrsConstants.GLOBAL_PROPERTY_LOCALE_ALLOWED_LIST, "en");
        properties.put(OpenmrsConstants.GLOBAL_PROPERTY_DEFAULT_LOCALE, "en");

        // EMR API
        properties.put(EmrApiConstants.PRIMARY_IDENTIFIER_TYPE, LiberiaPatientIdentifierTypes.PLEEBO_EMR_ID.name());

        // Core Apps
        properties.put(CoreAppsConstants.GP_DEFAULT_PATIENT_IDENTIFIER_LOCATION, LiberiaLocations.PLEEBO.uuid());

        setGlobalProperties(properties);
    }
}