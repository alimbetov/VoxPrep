package io.github.alimbetov.voxprep.backend.content.persistence;

import io.github.alimbetov.voxprep.backend.sharedkernel.Sha256Digest;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class Sha256DigestConverter implements AttributeConverter<Sha256Digest, String> {

    @Override
    public String convertToDatabaseColumn(Sha256Digest attribute) {
        return attribute == null ? null : attribute.value();
    }

    @Override
    public Sha256Digest convertToEntityAttribute(String dbData) {
        return dbData == null ? null : new Sha256Digest(dbData);
    }
}
