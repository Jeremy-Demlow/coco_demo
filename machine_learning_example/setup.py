"""Setup script for the anomaly detection ML package."""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="anomaly-detection-ml",
    version="0.1.0",
    author="ML Team",
    author_email="ml-team@example.com",
    description="Anomaly detection ML pipeline for Snowflake reconciliation data",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/example/anomaly-detection-ml",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Intended Audience :: Financial and Insurance Industry",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    python_requires=">=3.8",
    install_requires=[
        "numpy>=1.21.0",
        "pandas>=1.3.0",
        "scikit-learn>=1.0.0",
        "matplotlib>=3.4.0",
        "seaborn>=0.11.0",
        "snowflake-snowpark-python>=1.0.0",
        "snowflake-ml-python>=1.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=3.0.0",
            "black>=22.0.0",
            "flake8>=4.0.0",
            "mypy>=0.950",
        ],
    },
    entry_points={
        "console_scripts": [
            "anomaly-train=machine_learning_example.cli:train",
            "anomaly-predict=machine_learning_example.cli:predict",
        ],
    },
)
