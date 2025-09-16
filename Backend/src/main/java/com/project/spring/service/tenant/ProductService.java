package com.project.spring.service.tenant;
import java.nio.file.Paths;

import com.project.spring.model.tenant.Product;
import com.project.spring.repo.tenant.ProductRepository;
import com.project.spring.exception.ResourceNotFoundException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public Product createProduct(Product product) {
        return productRepository.save(product);
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public Product getProductById(Long productId) {
        return productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with ID: " + productId));
    }

    public Product updateProduct(Long productId, Product product) {
        Product existingProduct = getProductById(productId);
        existingProduct.setName(product.getName());
        existingProduct.setPrice(product.getPrice());
        existingProduct.setDescription(product.getDescription());
        return productRepository.save(existingProduct);
    }

    public void deleteProduct(Long productId) {
        productRepository.deleteById(productId);
    }

    public List<Product> createProduct(List<Product> products) {
        return productRepository.saveAll(products);
    }

    public List<Product> processProductsFromImage(MultipartFile file) throws Exception {
        // Save uploaded image temporarily
        File tempFile = File.createTempFile("upload-", ".jpg");
        file.transferTo(tempFile);
    
        // Run Python script
        ProcessBuilder pb = new ProcessBuilder(
                "python", "main.py", tempFile.getAbsolutePath()
        );
        pb.directory(new File(System.getProperty("user.dir") + "/python"));

        pb.redirectErrorStream(true);
    
        Process process = pb.start();
    
        StringBuilder outputBuilder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                outputBuilder.append(line);
            }
        }
    
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("Python script failed: " + outputBuilder);
        }
    
        // Parse JSON into Product list
        ObjectMapper mapper = new ObjectMapper();
        List<Product> products = mapper.readValue(outputBuilder.toString(), new TypeReference<List<Product>>() {});
    
        tempFile.delete();
    
        return products; // Return without saving
    }
    
}
