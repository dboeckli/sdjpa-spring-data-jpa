package ch.dboeckli.guru.jpa.hibernate.dao.repository;

import ch.dboeckli.guru.jpa.hibernate.dao.domain.Book;
import org.springframework.lang.Nullable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findBookByTitle(String title);

    Book readByTitle(String title);

    @Nullable
    Book getByTitle(@Nullable String title);

}
