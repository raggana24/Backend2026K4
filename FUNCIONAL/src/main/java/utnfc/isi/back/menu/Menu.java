package utnfc.isi.back.menu;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Scanner;

public class Menu {
    private final String title;
    private final List<MenuOption> options;

    public Menu(String title, List<MenuOption> options) {
        this.title = title;
        this.options = List.copyOf(options);
    }

    // ahora corre con contexto
    public void run(ApplicationContext ctx) {
        boolean createdScanner = false;
        Scanner in = ctx.get("in", Scanner.class);
        if (in == null) {
            in = new Scanner(System.in);
            ctx.put("in", in);
            createdScanner = true;
        }

        while (true) {
            printMenu();
            System.out.print("> ");
            String line = in.nextLine().trim();

            int code;
            try { code = Integer.parseInt(line); }
            catch (NumberFormatException e) {
                System.out.println("Entrada inválida: escribí un número.");
                continue;
            }

            if (code == 0) {
                System.out.println("¡Hasta luego!");
                break;
            }

            Optional<MenuOption> opt = options.stream()
                    .sorted(Comparator.comparingInt(MenuOption::code)) // ordena al mostrar
                    .filter(o -> o.code() == code)
                    .findFirst();

            if (opt.isEmpty()) {
                System.out.println("Opción inválida.");
                continue;
            }

            try {
                opt.get().action().run(ctx);
            } catch (Exception ex) {
                System.out.println("La acción falló: " + ex.getMessage());
            }
        }

        // cerramos el Scanner solo si lo creamos acá
        if (createdScanner) {
            try { in.close(); } finally { ctx.remove("in"); }
        }
    }

    private void printMenu() {
        System.out.println();
        System.out.println("=== " + title + " ===");
        options.stream()
                .sorted(Comparator.comparingInt(MenuOption::code))
                .forEach(o -> System.out.println(o.code() + ") " + o.label()));
        System.out.println("0) Salir");
    }
}