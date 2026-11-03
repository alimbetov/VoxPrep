package io.github.alimbetov.voxprep.backend.catalogue.persistence;

import io.github.alimbetov.voxprep.backend.content.persistence.ContentRevisionEntity;
import io.github.alimbetov.voxprep.backend.infrastructure.persistence.AbstractJpaEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Column;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.Objects;

@Entity
@Table(
        name = "catalogue_collection_content_member",
        schema = "app",
        uniqueConstraints = {
            @UniqueConstraint(
                    name = "uk_catalogue_collection_content_member__position",
                    columnNames = {"collection_id", "position"}),
            @UniqueConstraint(
                    name = "uk_catalogue_collection_content_member__revision",
                    columnNames = {"collection_id", "content_revision_id"})
        },
        indexes = {
            @Index(
                    name = "ix_catalogue_collection_content_member__collection_position",
                    columnList = "collection_id, position"),
            @Index(
                    name = "ix_catalogue_collection_content_member__revision",
                    columnList = "content_revision_id")
        })
public class CollectionContentMemberEntity extends AbstractJpaEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "collection_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_catalogue_collection_content_member__collection"))
    private LearningCollectionEntity collection;

    @Column(name = "position", nullable = false)
    private int position;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "content_revision_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_catalogue_collection_content_member__revision"))
    private ContentRevisionEntity contentRevision;

    protected CollectionContentMemberEntity() {
    }

    public CollectionContentMemberEntity(
            LearningCollectionEntity collection,
            int position,
            ContentRevisionEntity contentRevision) {
        this.collection = Objects.requireNonNull(collection, "collection");
        this.contentRevision = Objects.requireNonNull(contentRevision, "contentRevision");
        changePosition(position);
    }

    public void changePosition(int position) {
        if (position < 0) {
            throw new IllegalArgumentException("position must be >= 0");
        }
        this.position = position;
    }

    public LearningCollectionEntity getCollection() {
        return collection;
    }

    public int getPosition() {
        return position;
    }

    public ContentRevisionEntity getContentRevision() {
        return contentRevision;
    }
}
