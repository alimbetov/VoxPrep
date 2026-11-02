package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.sharedkernel.BusinessCode;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class BusinessCodeConverter implements AttributeConverter<BusinessCode, String> {

    @Override
    public String convertToDatabaseColumn(BusinessCode attribute) {
        return attribute == null ? null : attribute.value();
    }

    @Override
    public BusinessCode convertToEntityAttribute(String dbData) {
        return dbData == null ? null : new BusinessCode(dbData);
    }
}
