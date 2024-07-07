# esort

External sort utility, written in C++ using Seastar framework.

## Build

- Requires CMake 3.13.0, like Seastar.
- Seastar commit: 908ccd936a63a37cd98470ad8bf44a20d969c51e

```Bash
export seastar_dir=/Users/tomersha/Desktop/tomer/my-repos/seastar
cd esort
mkdir -p build
cmake -S . -G Ninja -DCMAKE_CXX_COMPILER=g++ -DCMAKE_PREFIX_PATH="$seastar_dir/build/release;$seastar_dir/build/release/_cooking/installed" -DCMAKE_MODULE_PATH=$seastar_dir/cmake -DENABLE_UBSAN=1 -B build
cmake --build build
```

## Run

```Bash
./build/esort <path>
```

## Test

I tested manually with the uncompressed `./testdata` examples on a Mac M1 Linux VM:

```Bash
$ uname -a
Linux ubuntu 6.5.10-orbstack-00110-gbcfe04c86d2f #1 SMP Fri Nov  3 10:20:37 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

- TODO: add automated integration testing unit testing (where needed), add fuzz tests, and perform active benchmarking, using OSS Google libs.
- TODO: profile and optimize.

## Improvements

- Investigate logs:

1. Reactor stalls.
2. Rate-limit: suppressed 12 backtraces on shard

- Bulkify I/O on sort and merge (I started with random I/O because it was simpler and due to time constraints). It should also improve memory allocation efficiency, by doing less bigger allocations,
using reserve() on record vectors.

1. Probe HW and decide a specific execution plan accordingly.
2. Do sequential reads and writes and parse the records in a memory buffer on HDDs (I/O is usually bottleneck on modern archs). Files may not be sequential, depending on the system state and the storage alogrithms. But for example a ScyllaDB server SSTable file should be mostly sequential.
3. On the other hand, SSDs supports parallel random access. Partition the file into smaller parts based on available memory per shard and issue I/O ops in parallel using seastar::parallel_for_each instead of seastar::do_for_each.
4. Try 2 on HDDs.
5. Measure 2,3,4.
6. Check `allocate_aligned_buffer`.

- Measure io_uring/aio/io_uring backends.
- Support memory relative memory_reserve_userspace_total_bytes, benchmark and fine tune the default setting.
- Add a setting min_shard_size_bytes or similar to shut sharding off for small files.
- Distribute the shard 0 centralized coordinator and avoid inefficient remote memory access on a NUMA node.
- Document effective max file size that is supported, by the used integer data types. Fine tune the types if needed.
- Probe the storage for block size (it may be 8KiB) and align record access to it.
- Assign parts to a subset of the shards if possible when part_count_per_shard_uniform == 0 using partial round-robin.
- Support other in memory sorting algorithms.
- On merge, do buffered sequential reads and writes per shard, based on allocated memory per shard, depending on the bulk I/O strategy as described above.
- Merge more parts at a time, as much as they fit in memory, to reduce merge pass count, depending on the bulk I/O strategy as described above.
- Optimize merge by applying an elevator algorithm that caches the last blocks on each pass.
- Consider using huge pages and locking memory.
- Cache open fds to reduce open() syscall count. Also rollover prev-prev pass files, using the fd cache, instead of additional opens and unmaps. Switch to use inter-shard file handles.
- Add a uuid to temporary file names to avoid collision.
- Consider decetralized coordination to improve parallelism. For example, we can leverge the tree model of merge-sort so that local serialization is needed only where nodes join bottom-up.
- Try optimize compiler ordering of branches with `[[likely]]` and `[[unlikely]]`. Better just do PGO.
- Try to embed `merge_pass_finalize` into `merge_two_parts` to become `merge_two_front_parts` with a valid new part inter-shard allocation.
