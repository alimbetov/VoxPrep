package io.github.alimbetov.voxprep.backend.sharedkernel;

public record RevisionNumber(int value) implements Comparable<RevisionNumber> {

    public RevisionNumber {
        if (value < 1) {
            throw new IllegalArgumentException("Revision number must be >= 1");
        }
    }

    public RevisionNumber next() {
        return new RevisionNumber(Math.addExact(value, 1));
    }

    @Override
    public int compareTo(RevisionNumber other) {
        return Integer.compare(value, other.value);
    }
}
