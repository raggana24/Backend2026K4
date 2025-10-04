package utnfc.isi.back.menu;

import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public final class ApplicationContext {
    private final ConcurrentMap<String, Object> store = new ConcurrentHashMap<>();

    private ApplicationContext() { }

    // Initialization-on-demand holder (lazy, thread-safe sin synchronized)
    private static class Holder {
        static final ApplicationContext INSTANCE = new ApplicationContext();
    }

    public static ApplicationContext getInstance() {
        return Holder.INSTANCE;
    }

    // ----- API mínima -----
    public void put(String key, Object value) {
        Objects.requireNonNull(key, "key");
        store.put(key, value); // upsert
    }

    public Object get(String key) {
        Objects.requireNonNull(key, "key");
        return store.get(key);
    }

    public <T> T get(String key, Class<T> type) {
        Objects.requireNonNull(key, "key");
        Objects.requireNonNull(type, "type");
        Object value = store.get(key);
        if (value == null) return null;
        if (!type.isInstance(value)) {
            throw new IllegalArgumentException("La clave '" + key + "' contiene " +
                    value.getClass().getName() + " y no es asignable a " + type.getName());
        }
        return type.cast(value);
    }

    public boolean contains(String key) {
        Objects.requireNonNull(key, "key");
        return store.containsKey(key);
    }

    public Object remove(String key) {
        Objects.requireNonNull(key, "key");
        return store.remove(key);
    }

    public void set(String key, Object newValue) {
        Objects.requireNonNull(key, "key");
        if (!store.containsKey(key)) {
            throw new NoSuchElementException("No existe la clave '" + key + "' para reemplazar (set).");
        }
        store.put(key, newValue);
    }

    // utilidades opcionales
    public Map<String, Object> snapshot() { return Map.copyOf(store); }
    public void clear() { store.clear(); }
}