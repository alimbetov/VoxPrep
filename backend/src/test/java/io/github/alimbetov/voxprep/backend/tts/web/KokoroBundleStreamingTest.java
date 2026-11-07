package io.github.alimbetov.voxprep.backend.tts.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import io.github.alimbetov.voxprep.backend.asset.application.ObjectStoragePort;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetKind;
import io.github.alimbetov.voxprep.backend.asset.domain.FileAssetStatus;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetEntity;
import io.github.alimbetov.voxprep.backend.asset.persistence.FileAssetRepository;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerApiKeyVerifier;
import io.github.alimbetov.voxprep.backend.tts.application.WorkerDeliveryProperties;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.security.MessageDigest;
import java.sql.ResultSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

class KokoroBundleStreamingTest {
    @Test
    @SuppressWarnings("unchecked")
    void streamsVerifiedBytesWithoutLegacyBufferedRead() throws Exception {
        byte[] bytes = "verified test model payload".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        UUID id = UUID.randomUUID();
        var props = new WorkerDeliveryProperties();
        props.setApiKey("piper-secret");
        props.setKokoroApiKey("kokoro-secret");
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        FileAssetRepository assets = mock(FileAssetRepository.class);
        ObjectStoragePort storage = mock(ObjectStoragePort.class);
        FileAssetEntity asset = mock(FileAssetEntity.class);
        when(asset.getKind()).thenReturn(FileAssetKind.TTS_MODEL);
        when(asset.getStatus()).thenReturn(FileAssetStatus.READY);
        when(asset.getSizeBytes()).thenReturn((long) bytes.length);
        when(asset.getSha256()).thenReturn(sha);
        when(asset.getBucket()).thenReturn("model-bucket");
        when(asset.getObjectKey()).thenReturn("models/pinned");
        when(assets.findById(id)).thenReturn(Optional.of(asset));
        when(jdbc.query(anyString(), any(RowMapper.class), any(Object[].class))).thenAnswer(call -> {
            RowMapper<Object> mapper = call.getArgument(1);
            ResultSet rs = mock(ResultSet.class);
            when(rs.getString("sha256")).thenReturn(sha);
            when(rs.getLong("size_bytes")).thenReturn((long) bytes.length);
            when(rs.getString("media_type")).thenReturn("application/octet-stream");
            return List.of(mapper.mapRow(rs, 0));
        });
        when(storage.openRead("model-bucket", "models/pinned"))
                .thenAnswer(inv -> new ByteArrayInputStream(bytes));
        var controller = new KokoroBundleDeliveryV2Controller(
                new WorkerApiKeyVerifier(props), jdbc, assets, storage);
        var result = controller.artifact("Bearer kokoro-secret", "kokoro-pinned", id);
        assertThat(result.getStatusCode().value()).isEqualTo(200);
        assertThat(result.getHeaders().getContentLength()).isEqualTo(bytes.length);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        result.getBody().writeTo(out);
        assertThat(out.toByteArray()).isEqualTo(bytes);
        verify(storage, times(2)).openRead("model-bucket", "models/pinned");
        verify(storage, never()).read(anyString(), anyString());
    }
}
