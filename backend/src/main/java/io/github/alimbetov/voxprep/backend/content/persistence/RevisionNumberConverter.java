package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.sharedkernel.RevisionNumber;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class RevisionNumberConverter implements AttributeConverter<RevisionNumber, Integer> {

    @Override
    public Integer convertToDatabaseColumn(RevisionNumber attribute) {
        return attribute == null ? null : attribute.value();
    }

    @Override
    public RevisionNumber convertToEntityAttribute(Integer dbData) {
        return dbData == null ? null : new RevisionNumber(dbData);
    }
}
