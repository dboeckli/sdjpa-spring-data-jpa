package ch.dboeckli.guru.jpa.hibernate.dao.dao.h2;

import ch.dboeckli.guru.jpa.hibernate.dao.dao.AuthorDao;
import ch.dboeckli.guru.jpa.hibernate.dao.dao.AuthorDaoImpl;
import ch.dboeckli.guru.jpa.hibernate.dao.domain.Author;
import jakarta.persistence.EntityNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.orm.jpa.JpaObjectRetrievalFailureException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertThrows;

@Import({ AuthorDaoImpl.class })
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@DataJpaTest
@Slf4j
class AuthorDaoImplTest {

    @Autowired
    AuthorDao authorDao;

    @Test
    void testDeleteAuthor() {
        Author author = new Author();
        author.setFirstName("john");
        author.setLastName("t");

        Author saved = authorDao.saveNewAuthor(author);

        authorDao.deleteAuthorById(saved.getId());

        assertThrows(JpaObjectRetrievalFailureException.class, () -> authorDao.getById(saved.getId()));
    }

    @Test
    void testUpdateAuthor() {
        Author author = new Author();
        author.setFirstName("john");
        author.setLastName("t");

        Author saved = authorDao.saveNewAuthor(author);

        saved.setLastName("Thompson");
        Author updated = authorDao.updateAuthor(saved);

        assertThat(updated.getLastName()).isEqualTo("Thompson");
    }

    @Test
    void testSaveAuthor() {
        Author author = new Author();
        author.setFirstName("John");
        author.setLastName("Thompson");
        Author saved = authorDao.saveNewAuthor(author);

        assertThat(saved).isNotNull();
    }

    @Test
    void testGetAuthorByName() {
        Author author = authorDao.findAuthorByName("Craig", "Walls");
        assertThat(author).isNotNull();
    }

    @Test
    void testGetAuthorByNameNotFound() {
        assertThrows(EntityNotFoundException.class, () -> authorDao.findAuthorByName("Gugus", "Hallo"));
    }

    @Test
    void testGetAuthor() {
        Author author = authorDao.getById(1L);
        assertThat(author).isNotNull();
    }

    @Test
    void findAllAuthorsByLastName() {
        List<Author> authors = authorDao.findAllAuthorsByLastName("Smith", PageRequest.of(0, 10));

        assertAll(
            () -> assertThat(authors).isNotNull(),
            () -> {
                assert authors != null;
                assertThat(authors.size()).isEqualTo(10);
            }
        );
    }

    @Test
    void findAllAuthorsByLastNameSortLastNameDesc() {
        List<Author> authors = authorDao.findAllAuthorsByLastName("Smith",
            PageRequest.of(0, 10, Sort.by(Sort.Order.desc("firstName"))));

        assertAll(
            () -> assertThat(authors).isNotNull(),
            () -> {
                assert authors != null;
                assertThat(authors.size()).isEqualTo(10);
            },
            () -> {
                assert authors != null;
                assertThat(authors.getFirst().getFirstName()).isEqualTo("Yugal");
            }
        );
    }

    @Test
    void findAllAuthorsByLastNameSortLastNameAsc() {
        List<Author> authors = authorDao.findAllAuthorsByLastName("Smith",
            PageRequest.of(0, 10, Sort.by(Sort.Order.asc("firstName"))));

        assertAll(
            () -> assertThat(authors).isNotNull(),
            () -> {
                assert authors != null;
                assertThat(authors.size()).isEqualTo(10);
            },
            () -> {
                assert authors != null;
                assertThat(authors.getFirst().getFirstName()).isEqualTo("Ahmed");
            }
        );
    }

    @Test
    void findAllAuthorsByLastNameAllRecs() {
        List<Author> authors = authorDao.findAllAuthorsByLastName("Smith", PageRequest.of(0, 100));

        assertAll(
            () -> assertThat(authors).isNotNull(),
            () -> {
                assert authors != null;
                assertThat(authors.size()).isEqualTo(40);
            }
        );
    }
}
