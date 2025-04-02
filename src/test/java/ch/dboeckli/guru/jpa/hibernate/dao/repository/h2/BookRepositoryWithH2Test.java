package ch.dboeckli.guru.jpa.hibernate.dao.repository.h2;

import ch.dboeckli.guru.jpa.hibernate.dao.domain.Book;
import ch.dboeckli.guru.jpa.hibernate.dao.repository.BookRepository;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.dao.EmptyResultDataAccessException;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.AssertionsForInterfaceTypes.assertThat;
import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
// we are using the h2 in compatible mode with mysql. to assure that it is not replaced with h2
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Slf4j
class BookRepositoryWithH2Test {

    @Autowired
    BookRepository bookRepository;

    @Test
    void testEmptyResultException() {
        assertThrows(EmptyResultDataAccessException.class, () -> bookRepository.readByTitle("foobar4"));
    }

    @Test
    void testNullParam() {
        assertNull(bookRepository.getByTitle(null));
    }

    @Test
    void testNoException() {
        assertNull(bookRepository.getByTitle("foo"));
    }

    @Test
    void testStreamFindAllByTitleNotNull() {
        AtomicInteger count = new AtomicInteger();
        bookRepository.findAllByTitleNotNull().forEach(book -> {
            log.info("Found book: {}", book);
            count.incrementAndGet();
        });
        assertThat(count.get()).isGreaterThan(0);
    }

    @Test
    void testQueryByTitleAsync() throws ExecutionException, InterruptedException {
        Future<Book> booksFuture = bookRepository.queryByTitle("Clean Code");
        Book book = booksFuture.get();

        assertNotNull(book);
    }

    @Test
    void testJpaTestSplice() {
        long countBefore = bookRepository.count();

        bookRepository.save(new Book("My Book", "1235555", "Self"));

        long countAfter = bookRepository.count();

        assertEquals(5, countBefore);
        assertEquals(6, countAfter);
    }

}