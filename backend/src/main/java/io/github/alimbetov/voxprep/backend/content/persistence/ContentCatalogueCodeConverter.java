package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class ContentCatalogueCodeConverter implements AttributeConverter<CatalogueCode, String> {

    @Override
    public String convertToDatabaseColumn(CatalogueCode attribute) {
        return attribute == null ? null : attribute.value();
    }

    @Override
    public CatalogueCode convertToEntityAttribute(String dbData) {
        return dbData == null ? null : new CatalogueCode(dbData);
    }
}
