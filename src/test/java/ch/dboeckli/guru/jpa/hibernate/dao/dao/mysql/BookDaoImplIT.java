package ch.dboeckli.guru.jpa.hibernate.dao.dao.mysql;

import ch.dboeckli.guru.jpa.hibernate.dao.dao.BookDao;
import ch.dboeckli.guru.jpa.hibernate.dao.dao.BookDaoImpl;
import ch.dboeckli.guru.jpa.hibernate.dao.domain.Author;
import ch.dboeckli.guru.jpa.hibernate.dao.domain.Book;
import jakarta.persistence.EntityNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.orm.jpa.JpaObjectRetrievalFailureException;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.AssertionsForInterfaceTypes.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

@ActiveProfiles("test_mysql")
@Import(BookDaoImpl.class)
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Slf4j
class BookDaoImplIT {

    @Autowired
    BookDao bookDao;

    @Test
    void testGetById() {
        Book book = bookDao.getById(3L);
        assertThat(book.getId()).isNotNull();
    }

    @Test
    void testFindBookByTitle() {
        Book book = bookDao.findBookByTitle("Clean Code");
        assertThat(book).isNotNull();
    }

    @Test
    void testFindBookByTitleNotFound() {
        assertThrows(EntityNotFoundException.class, () -> bookDao.findBookByTitle("Gugus"));
    }

    @Test
    void testSaveNewBook() {
        Book book = new Book();
        book.setIsbn("1234");
        book.setPublisher("Self");
        book.setTitle("my book");

        Author author = new Author();
        author.setId(3L);

        Book saved = bookDao.saveNewBook(book);

        assertThat(saved).isNotNull();
    }

    @Test
    void testUpdateBook() {
        Book book = new Book();
        book.setIsbn("1234");
        book.setPublisher("Self");
        book.setTitle("my book");

        Author author = new Author();
        author.setId(3L);

        Book saved = bookDao.saveNewBook(book);

        saved.setTitle("New Book");
        bookDao.updateBook(saved);

        Book fetched = bookDao.getById(saved.getId());

        assertThat(fetched.getTitle()).isEqualTo("New Book");
    }

    @Test
    void testDeleteBookById() {
        Book book = new Book();
        book.setIsbn("1234");
        book.setPublisher("Self");
        book.setTitle("my book");
        Book saved = bookDao.saveNewBook(book);

        bookDao.deleteBookById(saved.getId());

        assertThrows(JpaObjectRetrievalFailureException.class, () -> bookDao.getById(saved.getId()));
    }
}