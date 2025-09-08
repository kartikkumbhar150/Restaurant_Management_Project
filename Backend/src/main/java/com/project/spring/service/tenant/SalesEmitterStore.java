package com.project.spring.service.tenant;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.project.spring.repo.tenant.InvoiceRepository;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Service // use @Service here
public class SalesEmitterStore {

    private final InvoiceRepository invoiceRepository;

    private final List<SseEmitter> emitters = new CopyOnWriteArrayList<>();

    // Constructor injection ensures invoiceRepository is not null
    public SalesEmitterStore(InvoiceRepository invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }

    public SseEmitter subscribe() {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); // Never timeout unless disconnected
        emitters.add(emitter);

        emitter.onCompletion(() -> emitters.remove(emitter));
        emitter.onTimeout(() -> emitters.remove(emitter));
        emitter.onError(e -> emitters.remove(emitter));

        return emitter;
    }

    public void broadcast(double todaySales) {
        List<SseEmitter> deadEmitters = new CopyOnWriteArrayList<>();

        for (SseEmitter emitter : emitters) {
            try {
                emitter.send(SseEmitter.event().name("sale-update").data(todaySales));
            } catch (IOException e) {
                deadEmitters.add(emitter);
            }
        }

        emitters.removeAll(deadEmitters);
    }

    public String getTotal() {
        String today = LocalDate.now().toString();
        double total = invoiceRepository.getTodaySales(today);
        return String.valueOf(total);
    }

    public void updateAndBroadcast() {
        double total = invoiceRepository.getTodaySales(LocalDate.now().toString());
        broadcast(total);
    }
}
